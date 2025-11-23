args@{
  config,
  pkgs,
  lib,
  ...
}:
{
  buildDateTime = 1763870393;
  imports = [ ./los.nix ];
  manufactor = "google";
  kernel-short = "akita";
  enable-kernel = false;
  lindroid = true;
  microg.enable = false;
  gapps = true;
  device = "akita";
  flavorVersion = "22.2";
}
