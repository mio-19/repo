args@{ config, pkgs, ... }:
{
  buildDateTime = 1757600458;
  imports = [ ./common.nix ];
  manufactor = "samsung";
  kernel-short = "gta4xl";
  lindroid = true;
  defconfig = "arch/arm64/configs/exynos9611-gta4xlwifi_defconfig";
  legacy414 = true;
  ksu = false; # buggy # is it buggy because we installed magisk before?
  patch-daria = true;
  patch-overlayfs = true;
  device = "gta4xlwifi";
  flavorVersion = "22.2";
}
