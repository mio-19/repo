args@{
  config,
  pkgs,
  lib,
  ...
}:
{
  buildDateTime = 1763870393;
  imports = [ ./los.nix ];
  manufactor = "samsung";
  kernel-short = "gta4xl";
  lindroid = true;
  defconfig = "arch/arm64/configs/exynos9611-gta4xlwifi_defconfig";
  legacy414 = true;
  microg.enable = true;
  gapps = false;
  ksu = true;
  patch-overlayfs = true;
  device = "gta4xlwifi";
  flavorVersion = "23.0";
  kernel-patches = [
    # https://github.com/KernelSU-Next/KernelSU-Next/pull/743 -> -Note: legacy kernels: selfmusing/kernel_xiaomi_violet@9596554
    ./filter_count.patch
    ./0001-KSUManual4.14.patch
    ./daria.patch
    ./0001-we-don-t-have-linux-msm_drm_notify.h.patch
    ./0001-drop-master-lindroid-patch.patch
  ];
}
