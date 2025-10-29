args@{
  config,
  pkgs,
  lib,
  ...
}:
{
  buildDateTime = 1761702899;
  imports = [ ./common.nix ];
  manufactor = "samsung";
  kernel-short = "gta4xl";
  lindroid = true;
  defconfig = "arch/arm64/configs/exynos9611-gta4xlwifi_defconfig";
  legacy414 = true;
  microg.enable = false;
  gapps = true;
  ksu = true;
  patch-overlayfs = true;
  device = "gta4xlwifi";
  flavorVersion = "23.0";
  kernel-patches = [
    ./daria.patch
    ./0001-we-don-t-have-linux-msm_drm_notify.h.patch
    ./0001-drop-master-lindroid-patch.patch
  ];
}
