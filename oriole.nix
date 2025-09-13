args@{ config, pkgs, ... }:
{
  buildDateTime = 1757746157;
  imports = [ ./common.nix ];
  manufactor = "google";
  enable-kernel = false;
  lindroid = true;
  ksu = true;
  device = "oriole";
  flavorVersion = "22.2";
}
