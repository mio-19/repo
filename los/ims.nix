{
  config,
  lib,
  pkgs,
  ...
}:
let
  withIMS = config.withIMS;
  withIWLAN = config.withIWLAN;
in
{
  options = {
    withIMS = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Enable FLOSS IMS integration.";
    };

    withIWLAN = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Enable IWLAN and QualifiedNetworksService for IMS/WFC.";
    };
  };
  config = {

    # FLOSS IMS integration:
    # https://github.com/phhusson/ims/issues/22
    # https://github.com/TrebleDroid/treble_experimentations/wiki
    resources."frameworks/base/core/res" = lib.mkIf (withIMS && withIWLAN) {
      config_wlan_data_service_package = "com.google.android.iwlan";
      config_wlan_network_service_package = "com.google.android.iwlan";
      config_qualified_networks_service_package = "com.android.telephony.qns";
    };

    resources."packages/services/Telephony" = lib.mkIf withIMS {
      config_ims_mmtel_package = "me.phh.ims";
    };

    product.additionalProductPackages =
      (lib.optionals (withIMS && withIWLAN) [
        "Iwlan"
        "QualifiedNetworksService"
      ])
      ++
        # FlossIMS uses android.telephony.imsmedia.IImsMedia on newer releases.
        # Ensure the AOSP IMS media service exists so first-call media setup does not fail.
        (lib.optionals withIMS [
          "ImsMediaService"
          "libimsmedia"
        ]);

    product.extraConfig = lib.mkIf withIMS (
      ''
        PRODUCT_PRODUCT_PROPERTIES += persist.dbg.volte_avail_ovr=1
        PRODUCT_PRODUCT_PROPERTIES += persist.dbg.allow_ims_off=1
      ''
      + (
        if withIWLAN then
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
  };
}
