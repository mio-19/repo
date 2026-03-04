args@{
  config,
  pkgs,
  lib,
  ...
}:
{
  imports = [ ./los.nix ];
  manufactor = "samsung";
  kernel-short = "sm8250";
  lindroid = true;
  # https://github.com/LineageOS/android_kernel_samsung_sm8250
  defconfig = "arch/arm64/configs/gki_defconfig";
  legacy414 = false;
  microg.enable = false;
  gapps = true;
  ksu = false;
  patch-overlayfs = true;
  device = "gts7lwifi";
  flavorVersion = "23.2";
  kernel-patches = [
    ./kernel/0ac686b9e81ba331c2ad9b420fd21262a80daaa4.patch
  ];
  stateVersion = "3";
  graphics_ver = "7";
}
