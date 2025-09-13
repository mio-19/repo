args@{
  config,
  pkgs,
  lib,
  ...
}:
{
  imports = [ ./gta4xlwifi.nix ];
  flavorVersion = lib.mkForce "23.0";
}
