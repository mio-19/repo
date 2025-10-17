args@{
  config,
  pkgs,
  lib,
  ...
}:
{
  imports = [ ./gta4xlwifi22.nix ];
  flavorVersion = lib.mkForce "23.0";
}
