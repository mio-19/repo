args@{
  config,
  pkgs,
  lib,
  ...
}:
let
  sources = (import ./_sources/generated.nix) {
    inherit (pkgs)
      fetchurl
      fetchgit
      fetchFromGitHub
      dockerTools
      ;
  };
in
{
  buildDateTime = 1772004451;
  imports = [ ./los.nix ];
  manufactor = "samsung";
  kernel-short = "sm8550";
  defconfig = "arch/arm64/configs/dm3q_defconfig";
  device = "dm3q";
  flavorVersion = "23.2";
  lindroid = false;
  ksu = false;
  gapps = false;
  microg.enable = true;

  source.dirs = {
    "device/samsung/dm3q".src = sources.cola2261_device_dm3q.src;
    "device/samsung/sm8550-common".src = sources.cola2261_device_sm8550_common.src;
    "vendor/samsung/dm3q".src = sources.cola2261_vendor_dm3q.src;
    "vendor/samsung/sm8550-common".src = sources.cola2261_vendor_sm8550_common.src;
    "kernel/samsung/sm8550".src = sources.cola2261_kernel_sm8550.src;
    "kernel/samsung/sm8550-modules".src = sources.cola2261_kernel_sm8550_modules.src;
    "hardware/samsung".src = sources.cola2261_hardware_samsung.src;
  };
}
