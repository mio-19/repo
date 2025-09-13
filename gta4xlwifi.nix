args@{ config, pkgs, ... }:
{
  buildDateTime = 1757746157;
  imports = [ ./common.nix ];
  manufactor = "samsung";
  kernel-short = "gta4xl";
  lindroid = true;
  defconfig = "arch/arm64/configs/exynos9611-gta4xlwifi_defconfig";
  legacy414 = true;
  microg.enable = false; # use gapps https://github.com/MindTheGapps/15.0.0-arm64/releases/latest
  ksu = true;
  patch-daria = true;
  patch-overlayfs = true;
  device = "gta4xlwifi";
  flavorVersion = "22.2";
}
