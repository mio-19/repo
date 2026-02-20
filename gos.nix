args@{ config, pkgs, lib, ... }:
{
  buildDateTime = 1771555006;
  flavor = "grapheneos";
  grapheneos.channel = "alpha";
  source.dirs."frameworks/base".patches = [
    ./Disable-FLAG_SECURE.patch
    #./No-gestural-navigation-hint-bar.patch
  ];
}
