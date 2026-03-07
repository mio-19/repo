args@{
  config,
  pkgs-unstable,
  lib,
  ...
}:
let
  enableLindroid = false;
in
{
  imports = [
    ./gos.nix
    ./gos_lindroid.nix
    #./gos_userdebug.nix
  ];
  enableLindroid = enableLindroid; # basic stuff works. systemd units launched. sddm black screen.
  device = "husky";
  # check in nix repl (import ./.).gosSign.husky.config.source.dirs."device/google/shusky-kernels/6.1"
  source.dirs."device/google/shusky-kernels/6.1" = lib.mkForce {
    src =
      let
        src = pkgs-unstable.callPackage ./grapheneos_husky_kernel.nix { inherit enableLindroid; };
      in
      assert src.src.tag == config.grapheneos.release;
      src;
  };
  signing.avb.size = 4096;
  stateVersion = "2";
}
