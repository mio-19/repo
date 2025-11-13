args@{ config, pkgs, ... }:
{
  buildDateTime = 1763020000;
  flavor = "grapheneos";
  device = "akita";
  grapheneos.channel = "alpha";
  source.dirs."frameworks/base".patches = [
    ./Disable-FLAG_SECURE.patch
  ];
}
