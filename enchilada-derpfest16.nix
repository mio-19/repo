args@{
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
  imports = [ ./los.nix ];

  /*
    Source trail used to locate the DerpFest OnePlus 6 Android 16 repos:

    1. DerpFest upstream manifest shows active Android 16 / 16.2 branches:
       https://github.com/DerpFest-AOSP/android_manifest/branches
    2. The old official XDA thread for OnePlus 6 / 6T points kernel sources to
       ppanzenboeck and says the other required sources are in the same account:
       https://xdaforums.com/t/closed-moved-to-telegram-derpfest-14-official-for-oneplus-6-enchilada-oneplus-6t-fajita.4633973/
    3. From that maintainer account, the Android 16-era branches used here are:
       - device_oneplus_enchilada: derp16.2
       - device_oneplus_sdm845-common: derp16.2-4.9
       - kernel_oneplus_sdm845: derp16.2-4.9
       - hardware_oneplus: derp16.2
       Vendor repos for sdm845 stayed on older Lineage branches, so this file
       keeps the vendor pins separate from the Derp 16.2 device/kernel branches.
  */
  manufactor = "oneplus";
  kernel-short = "sdm845";
  defconfig = "arch/arm64/configs/enchilada_defconfig";
  device = "enchilada";
  flavorVersion = "23.2";
  stateVersion = "3";

  variant = "userdebug";
  gapps = true;
  microg.enable = false;
  legacy414 = true;
  lindroid = false;
  ksu = false;
  assertions = lib.mkForce [ ];

  source.dirs = {
    # DerpFest Android 16 / 16.2 maintainer trees for OnePlus 6 / 6T.
    "device/oneplus/enchilada".src = sources.derpfest16_device_oneplus_enchilada.src;
    "device/oneplus/sdm845-common".src = sources.derpfest16_device_oneplus_sdm845_common.src;
    "device/oneplus/sdm845-common".postPatch = ''
      substituteInPlace common.mk \
        --replace-fail '$(call inherit-product, packages/apps/ViPER4AndroidFX/config.mk)' ""
    '';
    "device/oneplus/sdm845-common".patches = [
      ./device-oneplus-sdm845-common-drop-stale-lineage-device-framework-matrix.patch
    ];
    "kernel/oneplus/sdm845".src = sources.derpfest16_kernel_oneplus_sdm845.src;
    "hardware/qcom-caf/bootctrl".patches = [
      ./hardware-qcom-caf-bootctrl-gpt-utils-select-string-false.patch
    ];
    "hardware/oneplus".src = sources.derpfest16_hardware_oneplus.src;

    # Vendor blobs kept on the Lineage lineage-22.1 branch by the same maintainer.
    "vendor/oneplus/enchilada".src = pkgs.fetchFromGitHub {
      owner = "ppanzenboeck";
      repo = "vendor_oneplus_enchilada";
      rev = "2dedc8d1099e0b4d3e507c0049ee9bdcf12d77f0";
      hash = "sha256-Tw9HIZ0AAIXLFFA5ZSot14eQ2K2hyEXG0kinXni0DC8=";
    };
    "vendor/oneplus/enchilada".patches = [
      ./vendor-oneplus-enchilada-update-radio-sha1.patch
    ];
    "vendor/oneplus/sdm845-common".src = pkgs.fetchFromGitHub {
      owner = "TheMuppets";
      repo = "proprietary_vendor_oneplus_sdm845-common";
      rev = "3d6b72f093ccfb99e8bfc17af204441b6e6322aa";
      hash = "sha256-Qa6vdg7+qmij7VMdHXSQ+wYDmYdwUcAd1RdiH47Dzgg=";
    };
    "vendor/oneplus/sdm845-common".patches = [
      ./vendor-oneplus-sdm845-common-drop-duplicate-libqti-perfd-client.patch
    ];
  };
}
