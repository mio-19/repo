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
    ./los_hardened_22_2.nix
    #./los_magisk.nix
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
  #magisk.enable = true;
  lindroid = false; # lindroid doesn't support 4.9?
  lindroid-drm = false; # /build/kernel/oneplus/sdm845/drivers/lindroid-drm/evdi_modeset.c:35:10: fatal error: 'drm/drm_gem_framebuffer_helper.h' file not found
  stateVersion = "2";
  enable-kernel = false;
  source.dirs."kernel/oneplus/sdm845" = lib.mkForce {
    src = self.packages.${pkgs.stdenv.hostPlatform.system}.kernelSrc.${config.device};
  };
}
