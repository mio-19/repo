args@{ config, pkgs, ... }:
{
  buildDateTime = 1757947744;
  imports = [ ./common.nix ];
  manufactor = "oneplus";
  kernel-short = "sdm845";
  defconfig = "arch/arm64/configs/enchilada_defconfig";
  device = "enchilada";
  flavorVersion = "22.2";
  gapps = true;
  microg.enable = false;
  #flavorVersion = "23.0";
  legacy49 = true;
  ksu = true; # DIFFICULT TO COMPILE KSU FOR 4.9 kernel
  lindroid = false; # lindroid doesn't support 4.9?
  lindroid-drm = false; # /build/kernel/oneplus/sdm845/drivers/lindroid-drm/evdi_modeset.c:35:10: fatal error: 'drm/drm_gem_framebuffer_helper.h' file not found
}
