args@{
  config,
  pkgs,
  lib,
  ...
}:
{
  imports = [ ./los.nix ];
  manufactor = "samsung";
  kernel-short = "gts7lwifi";
  lindroid = true;
  # https://github.com/LineageOS/android_kernel_samsung_sm8250
  defconfig = "arch/arm64/configs/gki_defconfig";
  legacy414 = false;
  microg.enable = false;
  gapps = true;
  ksu = false;
  patch-overlayfs = true;
  device = "gta4xlwifi";
  flavorVersion = "23.2";
  kernel-patches = [
  ];
}
