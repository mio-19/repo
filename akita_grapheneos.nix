args@{ config, pkgs, ... }:
{
  imports = [ ./gos.nix ];
  device = "akita";
  signing.avb.size = 2048;
  source.dirs."vendor/adevtool".patches = [
    #not needed# ./0001-akita-increase-default-zram-and-set-writeback-to-4G.patch
    ./vendor-adevtool-8G-4G-100.patch
  ];
}
