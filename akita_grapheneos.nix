args@{ config, pkgs, ... }:
{
  imports = [ ./gos.nix ];
  device = "akita";
  signing.avb.size = 2048;
  source.dirs."vendor/adevtool".patches = [
    ./0001-akita-increase-default-zram-and-set-writeback-to-4G.patch
  ];
}
