args@{ config, pkgs, ... }:
{
  buildDateTime = 1760140900;
  imports = [ ./common.nix ];
  manufactor = "nintendo";
  device-name = "nx";
  kernel-name = "nvidia/kernel-4.9-nx";
  defconfig = "arch/arm64/configs/tegra_android_defconfig";
  lindroid = false;
  legacy414 = true;
  # ksu doesn't compile
  #In file included from ../../../../../../kernel/nvidia/kernel-4.9-nx/drivers/kernelsu/throne_tracker.c:1:
  #../../../../../../kernel/nvidia/kernel-4.9-nx/drivers/kernelsu/throne_tracker.c: In function ‘track_throne’:
  #../../../../../../kernel/nvidia/kernel-4.9-nx/include/linux/err.h:30:9: error: ‘fp’ may be used uninitialized in this function [-Werror=maybe-uninitialized]
  #   30 |  return (long) ptr;
  #      |         ^~~~~~~~~~
  #../../../../../../kernel/nvidia/kernel-4.9-nx/drivers/kernelsu/throne_tracker.c:356:15: note: ‘fp’ was declared here
  #  356 |  struct file *fp;
  #      |               ^~
  #../../../../../../kernel/nvidia/kernel-4.9-nx/drivers/kernelsu/throne_tracker.c: At top level:
  #cc1: error: unrecognized command line option ‘-Wno-gcc-compat’ [-Werror]
  #cc1: all warnings being treated as errors
  ksu = false;
  device = "nx_tab";
  flavorVersion = "22.2";
}
