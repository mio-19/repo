args@{
  config,
  pkgs,
  lib,
  self,
  ...
}:
{
  imports = [
    ./los.nix
    ./los_hardened_23_2.nix
  ];
  manufactor = "samsung";
  kernel-short = "sm8250";
  lindroid = true;
  # https://github.com/LineageOS/android_kernel_samsung_sm8250
  defconfig = "arch/arm64/configs/gki_defconfig";
  legacy414 = false;
  microg.enable = false;
  gapps = true;
  ksu = true;
  patch-overlayfs = true;
  device = lib.mkDefault "gts7l";
  flavorVersion = "23.2";
  stateVersion = "3";
  graphics_ver = "7";
  enable-kernel = false;
  source.dirs."kernel/samsung/sm8250" = lib.mkForce {
    src =
      self.packages.${pkgs.stdenv.hostPlatform.system}.${config.device}.patchedKernelSrc.overrideAttrs
        (old: {
          # when building kernel in our robotnix build env, with patchShebangs: /nix/store/2hjsch59amjs3nbgh7ahcfzm2bfwl8zi-bash-5.3p9/bin/sh: symbol lookup error: /usr/lib/libc.so.6: undefined symbol: __nptl_change_stack_perm, version GLIBC_PRIVATE
          postPatch = builtins.replaceStrings [ "patchShebangs ." ] [ "" ] old.postPatch;
        });
  };
}
