args@{
  pkgs-unstable,
  lib,
  config,
  ...
}:
{
  imports = [
    ./gos
  ];
  device = "mustang";
  source.dirs."device/google/laguna-kernels/6.6" = lib.mkForce {
    src =
      let
        src = pkgs-unstable.callPackage ./gos_mustang_kernel.nix { };
      in
      assert src.version == config.grapheneos.release;
      src;

  };
  signing.avb.size = 4096;
  stateVersion = "3";
}
