args@{ config, pkgs, ... }:
{
  imports = [
    ./gos.nix
    #./gos_zswap.nix
  ];
  device = "akita";
  signing.avb.size = 2048;
}
