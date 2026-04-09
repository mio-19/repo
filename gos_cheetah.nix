args@{
  config,
  pkgs-unfree,
  lib,
  ...
}:
let
  enableLindroid = false;
in
{
  imports = [
    ./gos
  ];
  enableLindroid = enableLindroid;
  device = "cheetah";
  source.dirs."device/google/pantah-kernels/6.1" = lib.mkForce {
    src =
      let
        src = pkgs-unfree.callPackage ./gos_pantah_kernel.nix {
          inherit (config) enableLindroid enableDroidspaces;
        };
      in
      assert src.version == config.grapheneos.release;
      src;
  };
  stateVersion = "3";
}
