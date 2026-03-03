args@{
  config,
  pkgs,
  lib,
  ...
}:
let
  withIMS = args.withIMS or true;
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
  variant = "userdebug";
  buildDateTime = 1772004451;
  imports = [ ./los.nix ];
  manufactor = "samsung";
  kernel-short = "sm8550";
  defconfig = "arch/arm64/configs/dm3q_defconfig";
  device = "dm3q";
  flavorVersion = "23.2";
  lindroid = false;
  ksu = false;
  gapps = true;
  microg.enable = false;

  source.dirs = {
    "device/samsung/dm3q".src = sources.cola2261_device_dm3q.src;
    "device/samsung/sm8550-common".src = sources.cola2261_device_sm8550_common.src;
    "vendor/samsung/dm3q".src = sources.cola2261_vendor_dm3q.src;
    "vendor/samsung/sm8550-common".src = sources.cola2261_vendor_sm8550_common.src;
    "kernel/samsung/sm8550".src = sources.cola2261_kernel_sm8550.src;
    "kernel/samsung/sm8550-modules" = {
      src = sources.cola2261_kernel_sm8550_modules.src;
      postPatch = ''
                camera_makefile=qcom/opensource/camera-kernel/Makefile
                sed -i '/^cam_generated_h:/,/^$/c\
        cam_generated_h:\
        \t@:' "$camera_makefile"
                cat > qcom/opensource/camera-kernel/cam_generated_h <<'EOF'
        #define CAMERA_COMPILE_TIME "robotnix"
        #define CAMERA_COMPILE_BY "nix"
        #define CAMERA_COMPILE_HOST "nix"
        EOF
      '';
    };
    "hardware/samsung".src = sources.cola2261_hardware_samsung.src;
  };

  # FLOSS IMS integration:
  # https://github.com/phhusson/ims/issues/22
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
}
