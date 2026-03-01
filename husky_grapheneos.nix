args@{
  config,
  pkgs,
  lib,
  ...
}:
let
  huskyKernel = import ./grapheneos_husky_kernel.nix { inherit pkgs; };
in
{
  imports = [
    ./gos.nix
    ./gos_lindroid.nix
    #./gos_userdebug.nix
  ];
  device = "husky";
  # check in nix repl (import ./.).gosSign.husky.config.source.dirs."device/google/shusky-kernels/6.1"
  source.dirs."device/google/shusky-kernels/6.1" = lib.mkForce {
    src = huskyKernel;
  };
  signing.avb.size = 4096;
  stateVersion = "2";
}
