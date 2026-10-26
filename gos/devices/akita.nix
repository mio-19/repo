args@{ config, pkgs, ... }:
{
  imports = [
    ../default.nix
  ];
  device = "akita";
  signing.avb.size = 2048;
  stateVersion = "2";
}
