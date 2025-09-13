args@{ config, pkgs, ... }:
{
  buildDateTime = 1757750037;
  imports = [ ./common.nix ];
  manufactor = "samsung";
  kernel-short = "gta4xl";
  lindroid = true;
  defconfig = "arch/arm64/configs/exynos9611-gta4xlwifi_defconfig";
  legacy414 = true;
  microg.enable = false;
  #gapps = true; # manually install later
  ksu = true;
  patch-daria = true;
  patch-overlayfs = true;
  device = "gta4xlwifi";
  flavorVersion = "22.2";
}
