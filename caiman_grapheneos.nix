args@{
  config,
  pkgs-unstable,
  lib,
  ...
}:
{
  imports = [
    ./gos
  ];
  launcherVariant = "los";
  enableLindroid = false;
  enableDroidspaces = false;
  device = "caiman";
  source.dirs."device/google/caimito-kernels/6.1" = lib.mkForce {
    src =
      let
        src = pkgs-unstable.callPackage ./gos_caimito_kernel.nix {
          inherit (config) enableLindroid enableDroidspaces;
        };
      in
      assert src.version == config.grapheneos.release;
      src;
  };
  stateVersion = "3";
}
