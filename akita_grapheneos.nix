args@{ config, pkgs, ... }:
{
  buildDateTime = 1762391716;
  flavor = "grapheneos";
  device = "akita";
  grapheneos.channel = "stable";
  apps.fdroid.enable = true;
}
