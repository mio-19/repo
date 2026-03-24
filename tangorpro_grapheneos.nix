args@{
  config,
  pkgs-unstable,
  lib,
  ...
}:
let
  enableLindroid = true;
in
{
  imports = [
    ./gos.nix
    ./gos_lindroid.nix
    #./gos_userdebug.nix
  ];
  enableLindroid = enableLindroid;
  device = "tangorpro";
  source.dirs."device/google/tangorpro-kernels/6.1" = lib.mkForce {
    src =
      let
        src = pkgs-unstable.callPackage ./grapheneos_tangorpro_kernel.nix {
          inherit (config) enableLindroid enableDroidspaces;
        };
      in
      assert src.version == config.grapheneos.release;
      src;
  };
  stateVersion = "3";
}
