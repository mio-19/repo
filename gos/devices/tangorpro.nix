args@{
  config,
  pkgs-unfree,
  lib,
  ...
}:
{
  imports = [
    ../default.nix
  ];
  advancedPowerMenu = false;
  playIntegritySpoofing = true;
  allowAdbWirelessWithoutWifi = true;
  launcherVariant = "los";
  enableLindroid = true;
  enableDroidspaces = true;
  bundleLibrePods = true;
  device = "tangorpro";
  source.dirs."device/google/tangorpro-kernels/6.1" = lib.mkForce {
    src =
      let
        src = pkgs-unfree.callPackage ../kernels/tangorpro.nix {
          inherit (config) enableLindroid enableDroidspaces;
        };
      in
      assert src.version == config.grapheneos.release;
      src;
  };
  stateVersion = "3";
}
