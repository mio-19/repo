args@{
  config,
  pkgs,
  self,
  lib,
  ...
}:
{
  imports = [
    ./los.nix
    ./los_magisk.nix
  ];
  manufactor = "oneplus";
  kernel-short = "sdm845";
  defconfig = "arch/arm64/configs/enchilada_defconfig";
  device = "enchilada";
  flavorVersion = "22.2";
  gapps = true; # unfortunaly microg still cannot receive 2FA
  microg.enable = false;
  #flavorVersion = "23.0";
  legacy414 = true;
  ksu = false; # compiled but not working
  magisk.enable = true;
  lindroid = false; # lindroid doesn't support 4.9?
  lindroid-drm = false; # /build/kernel/oneplus/sdm845/drivers/lindroid-drm/evdi_modeset.c:35:10: fatal error: 'drm/drm_gem_framebuffer_helper.h' file not found
  stateVersion = "2";
  enable-kernel = false;
  source.dirs."kernel/oneplus/sdm845" = lib.mkForce {
    src =
      self.packages.${pkgs.stdenv.hostPlatform.system}.enchilada.patchedKernelSrc.overrideAttrs
        (old: {
          # when building kernel in our robotnix build env, with patchShebangs: /nix/store/2hjsch59amjs3nbgh7ahcfzm2bfwl8zi-bash-5.3p9/bin/sh: symbol lookup error: /usr/lib/libc.so.6: undefined symbol: __nptl_change_stack_perm, version GLIBC_PRIVATE
          postPatch = builtins.replaceStrings [ "patchShebangs ." ] [ "" ] old.postPatch;
        });
  };
}
