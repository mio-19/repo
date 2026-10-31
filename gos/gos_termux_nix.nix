{
  config,
  lib,
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
      Bind an already-installed Termux app's private Nix store directory to
      /nix after the primary Android user unlocks. This supports daemonless,
      single-user Nix and keeps the store owned by the Termux app UID. Termux
      is not bundled by this option.
    '';
  };

  config = lib.mkMerge [
    (lib.mkIf config.enableTermuxNix {
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
