args@{ config, pkgs, ... }:
{
  buildDateTime = 1761702899;
  flavor = "grapheneos";
  device = "akita";
  grapheneos.channel = "stable";
  apps.fdroid.enable = true;
}
