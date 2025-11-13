args@{ config, pkgs, ... }:
{
  buildDateTime = 1762946435;
  flavor = "grapheneos";
  device = "akita";
  grapheneos.channel = "alpha";
  source.dirs."frameworks/base".patches = [
    ./Disable-FLAG_SECURE.patch
  ];
}
