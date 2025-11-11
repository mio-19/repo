args@{ config, pkgs, ... }:
{
  buildDateTime = 1762868247;
  flavor = "grapheneos";
  device = "akita";
  grapheneos.channel = "alpha";
  apps.fdroid.enable = true;
}
