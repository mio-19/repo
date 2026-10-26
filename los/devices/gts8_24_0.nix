args@{
  config,
  pkgs,
  lib,
  ...
}:
let
  sources = (import ../../_sources/generated.nix) {
    inherit (pkgs)
      fetchurl
      fetchgit
      fetchFromGitHub
      dockerTools
      ;
  };
in
{
  # Galaxy Tab S8 5G (SM-X706).
  # Upstream only provides gts8wifi (SM-X700). We patch the device tree with the
  # gts8 device identity and lunch target, compile both gts8 and gts8wifi DTBOs
  # into a unified dtbo.img, and use the Wi-Fi-only profile to prevent RIL crash loops
  # until proprietary 5G modem/RIL blobs are extracted and integrated.
  variant = "user";
  imports = [
    ../default.nix
    ../hardened_24_0.nix
  ];
  manufactor = "samsung";
  kernel-short = "sm8450";
  defconfig = "arch/arm64/configs/gts8wifi_defconfig";
  device = "gts8";
  device-name = "gts8wifi";
  flavorVersion = "24.0";
  lindroid = false;
  ksu = false;
  gapps = true;
  microg.enable = false;

  source.dirs = {
    # No lineage-24.0 branch upstream yet for the device and vendor repos; reuse 23.2.
    "device/samsung/gts8wifi" = {
      src = sources.sm8450_tab_device_gts8wifi.src;
      patches = [
        ../patches/device-samsung-gts8wifi-add-gts8-support.patch
      ];
    };
    "vendor/samsung/gts8wifi".src = sources.sm8450_tab_vendor_gts8wifi.src;
    "kernel/samsung/sm8450" = {
      src = sources.sm8450_tab_24_kernel_sm8450.src;
      patches = [
        ../patches/kernel-samsung-sm8450-build-gts8-dtbos.patch
      ];
    };
    "kernel/samsung/sm8450-devicetrees".src = sources.sm8450_tab_24_kernel_sm8450_devicetrees.src;
    "kernel/samsung/sm8450-modules".src = sources.sm8450_tab_24_kernel_sm8450_modules.src;
    "hardware/samsung".src = sources.sm8450_tab_24_hardware_samsung.src;
    # The device tree needs the libagmclient headers exported by this fork.
    "hardware/qcom-caf/sm8450/audio/agm".src = sources.sm8450_tab_24_vendor_qcom_opensource_agm.src;
  };

  stateVersion = "3";
}
