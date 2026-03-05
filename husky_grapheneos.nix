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
  enableLindroid = enableLindroid;
  device = "husky";
  # check in nix repl (import ./.).gosSign.husky.config.source.dirs."device/google/shusky-kernels/6.1"
  source.dirs."device/google/shusky-kernels/6.1" = lib.mkForce {
    src = pkgs-unstable.callPackage ./grapheneos_husky_kernel.nix { inherit enableLindroid; };
  };
  signing.avb.size = 4096;
  stateVersion = "2";
}
