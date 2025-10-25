args@{ config, pkgs, ... }:
{
  buildDateTime = 1761403889;
  flavor = "grapheneos";
  device = "akita";
  grapheneos.channel = "stable";
  apps.fdroid.enable = true;
}
