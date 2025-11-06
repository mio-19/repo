args@{
  config,
  pkgs,
  lib,
  ...
}:
{
  buildDateTime = 1762391716;
  imports = [ ./common.nix ];
  manufactor = "google";
  kernel-short = "akita";
  enable-kernel = false;
  lindroid = true;
  microg.enable = false;
  gapps = true;
  device = "akita";
  flavorVersion = "22.2";
}
