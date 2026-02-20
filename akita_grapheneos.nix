args@{ config, pkgs, ... }:
{
  imports = [ ./gos.nix ];
  device = "akita";
  grapheneos.channel = "alpha";
  signing.avb.size = 2048;
}
