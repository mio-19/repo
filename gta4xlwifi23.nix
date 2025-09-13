args@{ config, pkgs, ... }:
{
  imports = [ ./gta4xlwifi.nix ];
  flavorVersion = lib.mkForce "23.0";
}
