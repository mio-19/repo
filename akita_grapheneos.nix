args@{ config, pkgs, ... }:
{
  buildDateTime = 1762925552;
  flavor = "grapheneos";
  device = "akita";
  grapheneos.channel = "alpha";
  apps.fdroid.enable = true;
  source.dirs."frameworks/base".patches = [
    ./frameworks-base-DisableFlagSecure.patch
  ];
}
