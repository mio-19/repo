args@{ config, pkgs, ... }:
{
  buildDateTime = 1771157080;
  flavor = "grapheneos";
  device = "husky";
  grapheneos.channel = "alpha";
  source.dirs."frameworks/base".patches = [
    ./Disable-FLAG_SECURE.patch
    #./No-gestural-navigation-hint-bar.patch
  ];
}
