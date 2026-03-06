args@{
  pkgs-unstable,
  lib,
  ...
}:
{
  imports = [
    ./gos.nix
  ];
  device = "mustang";
  source.dirs."device/google/laguna-kernels/6.6/grapheneos/muzel" = lib.mkForce {
    src = pkgs-unstable.callPackage ./grapheneos_mustang_kernel.nix { };
  };
  signing.avb.size = 4096;
  stateVersion = "2";
}
