args@{
  pkgs,
  lib,
  ...
}:
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
       - device_oneplus_sdm845-common: derp16.2
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
    "device/oneplus/enchilada".src = pkgs.fetchFromGitHub {
      owner = "ppanzenboeck";
      repo = "device_oneplus_enchilada";
      rev = "983aa8010f76c978e838e80d987bbd5a9990da03";
      hash = "sha256-S1lKJS+maEpdbKQ6cMMsh8kTuwLpkJ+jKADxpgGBb2M=";
    };
    "device/oneplus/sdm845-common".src = pkgs.fetchFromGitHub {
      owner = "ppanzenboeck";
      repo = "device_oneplus_sdm845-common";
      rev = "6a35ee792604a2feab55a3a42c4b78b5273beb3d";
      hash = "sha256-u/vsbIfsLXVdH9hPwGcZX34FzrS4SeSWZtHsj8ILVgA=";
    };
    "kernel/oneplus/sdm845".src = pkgs.fetchFromGitHub {
      owner = "ppanzenboeck";
      repo = "kernel_oneplus_sdm845";
      rev = "9b322418d63762b3bec0c824a656227a6607aa9d";
      hash = pkgs.lib.fakeHash;
    };
    "hardware/oneplus".src = pkgs.fetchFromGitHub {
      owner = "ppanzenboeck";
      repo = "hardware_oneplus";
      rev = "3c3057c888e46beb4cc0a909f70d24257af7a8a5";
      hash = "sha256-pnrTLQL+H9cuxLlbRVTJPY84GfW2ymJscIom/Wivnhc=";
    };

    # Vendor blobs kept on the Lineage lineage-22.1 branch by the same maintainer.
    "vendor/oneplus/enchilada".src = pkgs.fetchFromGitHub {
      owner = "ppanzenboeck";
      repo = "vendor_oneplus_enchilada";
      rev = "2dedc8d1099e0b4d3e507c0049ee9bdcf12d77f0";
      hash = "sha256-Tw9HIZ0AAIXLFFA5ZSot14eQ2K2hyEXG0kinXni0DC8=";
    };
    "vendor/oneplus/sdm845-common".src = pkgs.fetchFromGitHub {
      owner = "TheMuppets";
      repo = "proprietary_vendor_oneplus_sdm845-common";
      rev = "3d6b72f093ccfb99e8bfc17af204441b6e6322aa";
      hash = "sha256-Qa6vdg7+qmij7VMdHXSQ+wYDmYdwUcAd1RdiH47Dzgg=";
    };
  };
}
