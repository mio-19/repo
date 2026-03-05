args@{
  config,
  pkgs,
  lib,
  self,
  ...
}:
{
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
  flavorVersion = "23.2";
  kernel-patches = [
    # https://github.com/KernelSU-Next/KernelSU-Next/pull/743 -> -Note: legacy kernels: selfmusing/kernel_xiaomi_violet@9596554
    ./filter_count.patch
    ./0001-KSUManual4.14.patch
    ./daria.patch
    ./0001-we-don-t-have-linux-msm_drm_notify.h.patch
    ./0001-drop-master-lindroid-patch.patch
  ];
  stateVersion = "3";
  graphics_ver = "7";
  ksu-backport1 = true;
  enable-kernel = false;
  source.dirs."kernel/samsung/gta4xl" = lib.mkForce {
    src =
      self.packages.${pkgs.stdenv.hostPlatform.system}.gta4xlwifi.patchedKernelSrc.overrideAttrs
        (old: {
          # when building kernel in our robotnix build env, with patchShebangs: /nix/store/2hjsch59amjs3nbgh7ahcfzm2bfwl8zi-bash-5.3p9/bin/sh: symbol lookup error: /usr/lib/libc.so.6: undefined symbol: __nptl_change_stack_perm, version GLIBC_PRIVATE
          postPatch = builtins.replaceStrings [ "patchShebangs ." ] [ "" ] old.postPatch;
        });
  };
}
