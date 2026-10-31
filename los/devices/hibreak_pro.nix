args@{
  config,
  pkgs,
  lib,
  ...
}:
let
  withIMS = args.withIMS or true;
  withEinkService = args.withEinkService or true;
in
{
  variant = "userdebug";
  imports = [ ../default.nix ];

  /*
    Bigme HiBreak Pro (MediaTek MT6789 / Helio G99):
    Based on the custom LineageOS / Evolution X work by VBHA (vbbot) & community:
    - https://www.reddit.com/r/Bigme/comments/1kh6e70/android_15_evolution_x_lineage_os_fork_release/
    - https://www.reddit.com/r/ereader/comments/1kpes6e/hibreak_pro_eink_phone_thoughts_on_vbhas_custom/
    - https://github.com/vbbot/HibreakProPatchingService
    - https://github.com/vbbot/hibreak_pro_patches
  */
  manufactor = "xelex";
  kernel-short = "mt6789";
  defconfig = "arch/arm64/configs/gki_defconfig";
  device = "Q25";
  flavorVersion = "23.2";

  lindroid = false;
  ksu = false;
  gapps = true;
  microg.enable = false;

  source.dirs = {
    # LineageOS 23.2 device tree for Xelex Q25 / MT6789 platform
    "device/xelex/Q25".src = pkgs.fetchgit {
      url = "https://github.com/LineageOS/android_device_xelex_Q25.git";
      rev = "1f4e295b5b972bd5e5ea0ec01f8a87154973b464";
      sha256 = "0wnfxvk8nk8hzvvg11az2cx8x63vb3zma1aw8wy9dkg8xqqjc5g7";
    };

    # Vendor blobs tracking lineage-23.2
    "vendor/xelex/Q25".src = pkgs.fetchgit {
      url = "https://github.com/TheMuppets/proprietary_vendor_xelex_Q25.git";
      rev = "b8c2c8f90a211dbe16d14b198743e4ba8ea000e4";
      sha256 = "08k81rb0zj46332m2f11k3pcjc7rx3n37cs1hffj9942kn1hsl82";
    };

    # Kernel source (MediaTek MT6789 5.10 / GKI)
    "kernel/xelex/mt6789".src = pkgs.fetchFromGitHub {
      owner = "LineageOS";
      repo = "android_kernel_xelex_mt6789";
      rev = "2a873a3511ee0eeead1442e60145093192a4535d";
      sha256 = "0rp1v20ylsnasqb54r0kr99dh3h0axx0fhczzr12kkpf6mqh3vcx";
    };

    # MediaTek HALs & SEPolicy dependencies
    "hardware/mediatek".src = pkgs.fetchgit {
      url = "https://github.com/LineageOS/android_hardware_mediatek.git";
      rev = "68f9be72a32bca66e7c63d69e9739b18f13c8b48";
      sha256 = "1f27rp2y7l7z3dbx2b0nkcx2wczhy2r82f99kl9qqkj50rvc9w2z";
    };

    "device/mediatek/sepolicy_vndr".src = pkgs.fetchgit {
      url = "https://github.com/LineageOS/android_device_mediatek_sepolicy_vndr.git";
      rev = "b1c50f4903504168e7bd0e32b44c72d139d38d09";
      sha256 = "1hi3lqh6fn0fw1ykv81vsckdh0iyrywj72s5qb3z81g3gx5avlbz";
    };

    # E-Ink Accessibility Service & Daemon (Damian's A9 port adapted by VBHA for HiBreak Pro)
    "vendor/a9_services" = lib.mkIf withEinkService {
      src = pkgs.fetchgit {
        url = "https://github.com/vbbot/HibreakProPatchingService.git";
        rev = "e9516ffe20e479cf67cede0b9213e796ec8602c9";
        sha256 = "0f3q8l44lzixxslnpvdrxnx6gp7iwc1b9ys0icsikbah4vz9vdlr";
      };
    };

    # SurfaceFlinger fix from VBHA (001-permanently_disable_hw_overlays.patch):
    # Forces client composition in SurfaceFlinger, resolving the black screen / wake freeze on E-Ink.
    "frameworks/native".postPatch = ''
      substituteInPlace services/surfaceflinger/SurfaceFlinger.h \
        --replace-fail 'std::atomic_bool mDebugDisableHWC = false;' 'std::atomic_bool mDebugDisableHWC = true;'
      substituteInPlace services/surfaceflinger/SurfaceFlinger.cpp \
        --replace-fail 'mDebugDisableHWC = enabled;' 'enabled = true; mDebugDisableHWC = enabled;'
    '';
  };

  # Product packages (E-Ink service + FLOSS IMS)
  product.additionalProductPackages =
    (lib.optionals withEinkService [
      "a9_eink_server"
      "A9AccessibilityService"
    ])
    ++ (lib.optionals withIMS [
      "Iwlan"
      "QualifiedNetworksService"
    ]);

  # E-Ink, display, SurfaceFlinger, and IMS properties
  product.extraConfig = ''
    ${lib.optionalString withEinkService ''
      # E-Ink service autostart & default accessibility service
      PRODUCT_PROPERTY_OVERRIDES += persist.accessibility.enabled_service=com.lmqr.ha9_comp_service/.A9AccessibilityService

      # SurfaceFlinger & E-Ink display performance flags
      PRODUCT_PROPERTY_OVERRIDES += debug.sf.disable_backpressure=1
      PRODUCT_PROPERTY_OVERRIDES += debug.sf.disable_client_composition_cache=1
      PRODUCT_PROPERTY_OVERRIDES += ro.surface_flinger.force_hwc_copy_for_virtual_displays=true
      PRODUCT_PROPERTY_OVERRIDES += persist.sys.phh.forced_always_on=true

      # MediaTek platform performance
      PRODUCT_PROPERTY_OVERRIDES += ro.vendor.mtk.ged.kpi=1
    ''}
    ${lib.optionalString withIMS ''
      PRODUCT_PRODUCT_PROPERTIES += persist.dbg.volte_avail_ovr=1
      PRODUCT_PRODUCT_PROPERTIES += persist.dbg.wfc_avail_ovr=1
      PRODUCT_PRODUCT_PROPERTIES += persist.dbg.allow_ims_off=1
    ''}
  '';

  # FLOSS IMS / VoLTE / VoWiFi telephony integration (matching repo pattern in dm3q-cola2261)
  resources."frameworks/base/core/res" = lib.mkIf withIMS {
    config_wlan_data_service_package = "com.google.android.iwlan";
    config_wlan_network_service_package = "com.google.android.iwlan";
    config_qualified_networks_service_package = "com.android.telephony.qns";
  };
  resources."packages/services/Telephony" = lib.mkIf withIMS {
    config_ims_mmtel_package = "me.phh.ims";
  };

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
