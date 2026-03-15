{
  config,
  lib,
  pkgs,
  ...
}:
let
  withIMS = config.withIMS;
  withIWLAN = config.withIWLAN;
  samsungIMSUseFullStack = config.samsungIMSUseFullStack;
  samsungIMSVendorSrc = config.samsungIMSVendorSrc;
  samsungIMSApk = config.samsungIMSApk;
  samsungIMSPackageName = config.samsungIMSPackageName;
in
{
  options = {
    withIMS = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Enable IMS integration.";
    };

    withIWLAN = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Enable IWLAN/QNS integration for WFC.";
    };

    samsungIMSUseFullStack = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = ''
        Use the full Samsung IMS vendor stack (vendor-ims.mk + proprietary
        binaries/jars/config) instead of APK-only deployment.
      '';
    };

    samsungIMSVendorSrc = lib.mkOption {
      type = lib.types.path;
      default = pkgs.runCommand "samsung-ims-vendor-src" { } ''
        cp -r ${pkgs.fetchFromGitHub {
          owner = "jameskdev";
          repo = "android_samsung_imsservice";
          rev = "a8ca989d3d066d74fc9ec3a8032f0ca4553baeb5";
          hash = "sha256-1gpimATRINIfVjxa3AJi0AjDh0cVhvZkNfAWXrCLnbU=";
        }}/proprietary_vendor_samsung_ims/. "$out"
      '';
      example = lib.literalExpression "pkgs.fetchFromGitHub { owner = \"jameskdev\"; repo = \"android_samsung_imsservice\"; rev = \"a8ca989d3d066d74fc9ec3a8032f0ca4553baeb5\"; hash = \"sha256-1gpimATRINIfVjxa3AJi0AjDh0cVhvZkNfAWXrCLnbU=\"; }";
      description = ''
        Source tree for vendor/samsung/ims (expects Android.mk, vendor-ims.mk,
        and proprietary/ content as in jameskdev/android_samsung_imsservice/
        proprietary_vendor_samsung_ims).
      '';
    };

    samsungIMSApk = lib.mkOption {
      type = lib.types.path;
      default = samsungIMSVendorSrc + "/proprietary/system/priv-app/imsservice/imsservice.apk";
      description = ''
        Path to a patched Samsung imsservice APK.
        Defaults to the APK in samsungIMSVendorSrc.
      '';
    };

    samsungIMSPackageName = lib.mkOption {
      type = lib.types.str;
      default = "com.sec.imsservice";
      description = "IMS service package name to set in Telephony resource overlay.";
    };
  };

  config = {
    assertions = [
      {
        assertion =
          (!withIMS)
          || (samsungIMSUseFullStack && samsungIMSVendorSrc != null)
          || ((!samsungIMSUseFullStack) && samsungIMSApk != null);
        message = ''
          withIMS=true in los_samsungims.nix requires either:
          - samsungIMSUseFullStack=true and samsungIMSVendorSrc set, or
          - samsungIMSUseFullStack=false and samsungIMSApk set.
        '';
      }
    ];

    # Samsung IMS integration (alternative backend to los_ims.nix / FlossIMS).
    # Reference:
    # - https://github.com/jameskdev/android_samsung_imsservice
    # - https://xdaforums.com/t/research-wip-possible-volte-enablement-for-samsung-devices-on-aosp-based-roms.4664947/
    # Note: full Samsung IMS bring-up can also require proprietary jars/libs/rc files
    # shown in proprietary_vendor_samsung_ims/vendor-ims.mk.
    source.dirs."vendor/samsung/ims".src = lib.mkIf (withIMS && samsungIMSUseFullStack) samsungIMSVendorSrc;

    # Pull in Samsung's vendor IMS makefile into the device product definition.
    source.dirs."device/${config.manufactor}/${config.device-name}".postPatch =
      lib.mkIf (withIMS && samsungIMSUseFullStack)
        (lib.mkAfter ''
          echo '$(call inherit-product, vendor/samsung/ims/vendor-ims.mk)' >> device.mk
        '');

    resources."frameworks/base/core/res" = lib.mkIf (withIMS && withIWLAN) {
      config_wlan_data_service_package = "com.google.android.iwlan";
      config_wlan_network_service_package = "com.google.android.iwlan";
      config_qualified_networks_service_package = "com.android.telephony.qns";
    };

    resources."packages/services/Telephony" = lib.mkIf withIMS {
      config_ims_mmtel_package = samsungIMSPackageName;
    };

    product.additionalProductPackages = lib.mkIf (withIMS && withIWLAN) [
      "Iwlan"
      "QualifiedNetworksService"
    ];

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

    apps.prebuilt.SamsungIMSService = lib.mkIf (withIMS && (!samsungIMSUseFullStack)) {
      apk = samsungIMSApk;
      packageName = samsungIMSPackageName;
      certificate = "platform";
      privileged = true;
      partition = "system";
      extraConfig = ''
        LOCAL_DEX_PREOPT := false
        LOCAL_CERTIFICATE := platform
      '';
    };
  };
}
