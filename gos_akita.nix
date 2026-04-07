args@{ config, pkgs, ... }:
{
  imports = [
    ./gos
  ];
  device = "akita";
  signing.avb.size = 2048;
  stateVersion = "2";
}
