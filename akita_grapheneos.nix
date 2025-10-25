args@{ config, pkgs, ... }:
{
  buildDateTime = 1761299407;
  flavor = "grapheneos";
  device = "akita";
  grapheneos.channel = "stable";
  apps.fdroid.enable = true;
}
