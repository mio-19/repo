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
  advancedPowerMenu = true;
  launcherVariant = "los";
  allowAdbWirelessWithoutWifi = true;
  enableLindroid = true;
  enableDroidspaces = true;
  device = "tangorpro";
  source.dirs."device/google/tangorpro-kernels/6.1" = lib.mkForce {
    src =
      let
        src = pkgs-unstable.callPackage ./gos_tangorpro_kernel.nix {
          inherit (config) enableLindroid enableDroidspaces;
        };
      in
      assert src.version == config.grapheneos.release;
      src;
  };
  stateVersion = "3";
}
