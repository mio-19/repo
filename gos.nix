args@{
  config,
  pkgs,
  lib,
  ...
}:
{
  buildDateTime = 1771586071;
  flavor = "grapheneos";
  grapheneos.channel = "alpha";
  source.dirs."frameworks/base".patches = [
    ./Disable-FLAG_SECURE.patch
    #./No-gestural-navigation-hint-bar.patch
  ];
}
