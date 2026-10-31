{
  config,
  lib,
  pkgs,
  self,
  ...
}:
let
  enableVirtualMachinePolicy = config.bundleLimboTensor || config.bundleDroidVM;
in
{
  options.enableTermuxNix = lib.mkOption {
    type = lib.types.bool;
    default = false;
    description = ''
      Bundle Termux and bind its app-owned private Nix store directory to /nix
      after the primary Android user unlocks. This supports daemonless,
      single-user Nix and keeps the store owned by the Termux app UID.
    '';
  };

  config = lib.mkMerge [
    (lib.mkIf config.enableTermuxNix {
      apps.prebuilt.termux = {
        enable = true;
        name = "Termux";
        packageName = "com.termux";
        apk = "${self.packages.${pkgs.stdenv.hostPlatform.system}.apk_termux}/termux.apk";
      };
      # Keep Termux in its normal app domain so its app-data executable policy
      # also applies to Nix binaries in the bind-mounted private store.
      # Downstream extension against GrapheneOS platform_system_core init.rc
      # (AOSP, Apache-2.0): https://github.com/GrapheneOS/platform_system_core
      source.dirs."system/core".patches = [ ./termux-nix-init.patch ];
    })
    (lib.mkIf enableVirtualMachinePolicy {
      # Downstream extension against GrapheneOS platform_system_sepolicy
      # (AOSP, Apache-2.0): https://github.com/GrapheneOS/platform_system_sepolicy
      source.dirs."system/sepolicy".patches = [ ./virtual-machine-sepolicy.patch ];
    })
  ];
}
