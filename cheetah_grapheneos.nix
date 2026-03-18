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
  device = "cheetah";
  source.dirs."device/google/pantah-kernels/6.1" = lib.mkForce {
    src =
      let
        src = pkgs-unstable.callPackage ./grapheneos_pantah_kernel.nix { inherit enableLindroid; };
      in
      assert src.version == config.grapheneos.release;
      src;
  };
  stateVersion = "3";
}
