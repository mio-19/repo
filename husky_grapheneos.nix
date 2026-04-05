args@{
  config,
  pkgs-unstable,
  lib,
  ...
}:
{
  imports = [
    ./gos.nix
    #./gos_userdebug.nix
  ];
  enableLindroid = false; # basic stuff works. systemd units launched. sddm black screen.
  enableDroidspaces = true;
  device = "husky";
  # check in nix repl (import ./.).gosSign.husky.config.source.dirs."device/google/shusky-kernels/6.1"
  source.dirs."device/google/shusky-kernels/6.1" = lib.mkForce {
    src =
      let
        src = pkgs-unstable.callPackage ./grapheneos_husky_kernel.nix {
          inherit (config) enableLindroid enableDroidspaces;
        };
      in
      assert src.version == config.grapheneos.release;
      src;
  };
  signing.avb.size = 4096;
  stateVersion = "3";
}
