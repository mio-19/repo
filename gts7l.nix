args@{
  config,
  pkgs,
  lib,
  self,
  ...
}:
let
  withIMS = args.withIMS or (config.device == "gts7l");
  # Keep IWLAN disabled by default so we can prioritize stable VoLTE bring-up
  # on Samsung RIL before adding WFC/epdg complexity.
  # https://github.com/phhusson/ims/issues/26
  wthIWLAN = false;
in
{
  imports = [
    ./los.nix
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
  flavorVersion = "23.2";
  stateVersion = "3";
  graphics_ver = "7";
  enable-kernel = false;
  source.dirs."kernel/samsung/sm8250" = lib.mkForce {
    src = self.packages.${pkgs.stdenv.hostPlatform.system}."kernelSrc-${config.device}";
  };

  # FLOSS IMS integration:
  # https://github.com/phhusson/ims/issues/22
  resources."frameworks/base/core/res" = lib.mkIf (withIMS && wthIWLAN) {
    config_wlan_data_service_package = "com.google.android.iwlan";
    config_wlan_network_service_package = "com.google.android.iwlan";
    config_qualified_networks_service_package = "com.android.telephony.qns";
  };
  resources."packages/services/Telephony" = lib.mkIf withIMS {
    config_ims_mmtel_package = "me.phh.ims";
  };

  product.additionalProductPackages = lib.mkIf (withIMS && wthIWLAN) [
    "Iwlan"
    "QualifiedNetworksService"
  ];

  product.extraConfig = lib.mkIf withIMS (
    ''
      PRODUCT_PRODUCT_PROPERTIES += persist.dbg.volte_avail_ovr=1
      PRODUCT_PRODUCT_PROPERTIES += persist.dbg.allow_ims_off=1
    ''
    + (
      if wthIWLAN then
        ''
          PRODUCT_PRODUCT_PROPERTIES += persist.dbg.wfc_avail_ovr=1
        ''
      else
        ''
          PRODUCT_PRODUCT_PROPERTIES += persist.dbg.wfc_avail_ovr=0
        ''
    )
  );

  apps.prebuilt.FlossIMS = lib.mkIf withIMS {
    apk = pkgs.fetchurl {
      # Long-term: always re-sign in-build with platform key so sharedUser matches
      # both test-key builds and release-script signed builds.
      url = "https://treble.phh.me/floss-ims-84.apk";
      sha256 = "0wvkkbjm2q22bjv4w2cdjch917svpn6nqlihirwcpm1bbqkk6j8i";
    };
    packageName = "me.phh.ims";
    certificate = "platform";
    privileged = true;
    partition = "system";
    # Override robotnix prebuilt key path so this APK is signed with build platform key.
    extraConfig = ''
      LOCAL_DEX_PREOPT := false
      LOCAL_CERTIFICATE := platform
    '';
  };
}
