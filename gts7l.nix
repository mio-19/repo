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
    ./los_ims.nix
    #./los_hardened_23_2.nix # does this break lindroid?
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
  withIMS = args.withIMS or (config.device == "gts7l");
  # Keep IWLAN disabled by default so we can prioritize stable VoLTE bring-up
  # on Samsung RIL before adding WFC/epdg complexity.
  # https://github.com/phhusson/ims/issues/26
  withIWLAN = false;
  flavorVersion = "23.2";
  stateVersion = "3";
  graphics_ver = "7";
  enable-kernel = false;
  source.dirs."kernel/samsung/sm8250" = lib.mkForce {
    src = self.packages.${pkgs.stdenv.hostPlatform.system}."kernelSrc-${config.device}";
  };
}
