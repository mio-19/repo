args@{ config, pkgs, ... }:
{
  imports = [
    ./gos.nix
  ];
  device = "akita";
  signing.avb.size = 2048;
  stateVersion = "2";
}
