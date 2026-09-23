# WARNING: Samsung Galaxy S21 Ultra Snapdragon (p3q)
# There is currently NO full AOSP / LineageOS device tree for this device.
# 1. The US/Canada models (G998U/U1/W) have locked bootloaders.
# 2. The Chinese/HK model (G9980) has an unlockable bootloader, but developers
#    only build OneUI-based custom ROMs (like UN1CA) rather than full AOSP.
# The repositories linked below are only for TWRP recovery and generic sm8350 kernels.
# This configuration is a stub and WILL NOT compile a full LineageOS ROM.
args@{
  config,
  pkgs,
  lib,
  ...
}:
let
  withIMS = args.withIMS or true;
in
{
  variant = "userdebug";
  imports = [ ./los.nix ];
  manufactor = "samsung";
  kernel-short = "sm8350";
  defconfig = "arch/arm64/configs/p3q_defconfig";
  device = "p3q";
  flavorVersion = "23.2";
  lindroid = false;
  ksu = false;
  gapps = true;
  microg.enable = false;

  # TODO: We need the actual Git repositories for the S21 Ultra Snapdragon (p3q)
  # Uncomment and populate these once the device trees are available.
  source.dirs = {
    "device/samsung/p3q".src = pkgs.fetchgit {
      url = "https://github.com/afaneh92/android_device_samsung_p3q.git";
      rev = "android-11"; # TWRP branch
      sha256 = lib.fakeSha256;
    };
    # "device/samsung/sm8350-common".src = pkgs.fetchgit { ... };
    # "vendor/samsung/p3q".src = pkgs.fetchgit { ... };
    # "vendor/samsung/sm8350-common".src = pkgs.fetchgit { ... };
    "kernel/samsung/sm8350".src = pkgs.fetchgit {
      url = "https://github.com/samsung-sm8350/android_kernel_samsung_sm8350.git";
      rev = "lineage-22";
      sha256 = lib.fakeSha256;
    };
    # "hardware/samsung".src = pkgs.fetchgit { ... };
  };

  # FLOSS IMS integration for VoLTE / Wi-Fi Calling
  resources."frameworks/base/core/res" = lib.mkIf withIMS {
    config_wlan_data_service_package = "com.google.android.iwlan";
    config_wlan_network_service_package = "com.google.android.iwlan";
    config_qualified_networks_service_package = "com.android.telephony.qns";
  };
  resources."packages/services/Telephony" = lib.mkIf withIMS {
    config_ims_mmtel_package = "me.phh.ims";
  };

  product.additionalProductPackages = lib.mkIf withIMS [
    "Iwlan"
    "QualifiedNetworksService"
  ];

  product.extraConfig = lib.mkIf withIMS ''
    PRODUCT_PRODUCT_PROPERTIES += persist.dbg.volte_avail_ovr=1
    PRODUCT_PRODUCT_PROPERTIES += persist.dbg.wfc_avail_ovr=1
    PRODUCT_PRODUCT_PROPERTIES += persist.dbg.allow_ims_off=1
  '';

  apps.prebuilt.FlossIMS = lib.mkIf withIMS {
    apk = pkgs.fetchurl {
      url = "https://treble.phh.me/floss-ims-16.apk";
      sha256 = "1wjld0b8miavcbyxh2gn2ck690dxw8qrycskdrgmdd8w8am6qiam";
    };
    packageName = "me.phh.ims";
    certificate = "platform";
    privileged = true;
    partition = "system";
  };
  
  stateVersion = "3";
}
