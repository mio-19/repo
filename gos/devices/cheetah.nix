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
    ../default.nix
  ];
  enableLindroid = enableLindroid;
  device = "cheetah";
  source.dirs."device/google/pantah-kernels/6.1" = lib.mkForce {
    src =
      let
        src = pkgs-unfree.callPackage ../kernels/pantah.nix {
          inherit (config) enableLindroid enableDroidspaces enableUnprotectedKvm;
        };
      in
      assert src.version == config.grapheneos.release;
      src;
  };
  stateVersion = "3";
}
