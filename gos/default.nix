args@{
  pkgs,
  pkgs-unstable,
  lib,
  config,
  self,
  ...
}:
let
  sources = (import ../_sources/generated.nix) {
    inherit (pkgs)
      fetchurl
      fetchgit
      fetchFromGitHub
      dockerTools
      ;
  };
  inherit (pkgs) fetchpatch;
  replace_app = name: attribute: ''
    rm prebuilt/${name}.apk
    rm -f prebuilt/${name}.apk.idsig # maybe not exist
    lower_name="${lib.toLower name}"
    keystore="$TMPDIR/grapheneos-''${lower_name}-signing-key.jks"

    # We don't expect out of band upgrade so use a key generated every time.
    ${lib.getExe' pkgs.jdk "keytool"} -genkeypair \
      -keystore "$keystore" \
      -storepass android \
      -keypass android \
      -alias androiddebugkey \
      -keyalg RSA \
      -keysize 4096 \
      -validity 10000 \
      -dname "CN=GrapheneOS ${name},O=GrapheneOS,C=US"

    ${lib.getExe self.packages.${pkgs.stdenv.hostPlatform.system}.${attribute}.signScript} \
      "$keystore" \
      --ks-pass android \
      --out prebuilt/${name}.apk
  '';
in
{
  imports = [
    ./gos_noleakdns.nix
    ./gos-apple.nix
    ./gos_lindroid.nix
    ./launcher.nix
    ./gos_userdebug.nix
  ];
  buildDateTime = 1775310433;
  flavor = "grapheneos";
  grapheneos.channel = "alpha";
  source.dirs."frameworks/base".patches = [
    (fetchpatch {
      name = "Make App restart required Notification not deletable";
      url = "https://github.com/GrapheneOS/platform_frameworks_base/pull/263.diff";
      hash = "sha256-Hw3BLHwJsXmu5482QWZC+DsqBDxaV0F1fCDgwna5AVQ=";
    })
    #./No-gestural-navigation-hint-bar.patch

    #./Disable-FLAG_SECURE.patch
    # https://github.com/GrapheneOS/os-issue-tracker/issues/664#issuecomment-3937125786
    (fetchpatch {
      name = "Add a toggle to allow screenshots through FLAG SECURE";
      url = "https://github.com/GrapheneOS/platform_frameworks_base/pull/313.patch";
      hash = "sha256-S3zWY9AFAS2iKVPEl8p03HhidOxdKXs0BEG10jVxWZQ=";
    })

    (fetchpatch {
      name = "Add toggle to hide location access indicator on a per-app basis.patch";
      url = "https://github.com/GrapheneOS/platform_frameworks_base/pull/305.patch";
      hash = "sha256-VGaxcAWyLeItvQjSFJceCWhWj8IvJ7iquuJOLwpfo1I=";
    })
    /*
      # cannot apply
      (fetchpatch {
        name = "Possibly fix NPE";
        url = "https://github.com/GrapheneOS/platform_frameworks_base/pull/258.patch";
        hash = "sha256-/2yXOeHQmuJDngLypCz512F5jWdT3oZ9MGjthC5/Tp0=";
      })
    */
    (fetchpatch {
      name = "SystemUI: Open Tethering settings from QS Hotspot tile";
      url = "https://github.com/GrapheneOS/platform_frameworks_base/pull/323.patch";
      hash = "sha256-qNylnt+S2lIt30D9gwnbW7jcf+rb7zDV3c6tS877AuQ=";
    })
  ];
  source.dirs."packages/apps/Settings".patches = [
    # https://github.com/GrapheneOS/os-issue-tracker/issues/664#issuecomment-3937125786
    (fetchpatch {
      name = "Add a toggle to disable FLAG SECURE";
      url = "https://github.com/GrapheneOS/platform_packages_apps_Settings/pull/411.patch";
      hash = "sha256-hcztYEyhfDlfkx04lKmsEOKr2puoM6GUb3bhRIgiCaM=";
    })
  ];
  source.dirs."packages/modules/Permission".patches = [
    # adapted from https://github.com/GrapheneOS/platform_packages_modules_Permission/pull/83
    ./location-indicator-per-app.patch
  ];
  source.dirs."packages/apps/Dialer".patches = [
    # https://github.com/GrapheneOS/platform_packages_apps_Dialer/pull/48
    (fetchpatch {
      name = "Add automatic call recording.patch";
      url = "https://github.com/GrapheneOS/platform_packages_apps_Dialer/commit/4b2b28c36e3f0a29e2f7d171e9ae1128d54eb27c.patch";
      hash = "sha256-ceo+c99iyYeaweks1Hk/VYXl8pa3PMGtcbHcxOLRM4k=";
    })
  ];
  source.dirs."packages/apps/AppCompatConfig".patches = [
    (fetchpatch {
      name = "add configs for Brave beta and Brave nightly.patch";
      url = "https://github.com/GrapheneOS/platform_packages_apps_AppCompatConfig/pull/6.patch";
      hash = "sha256-QoabShVmthSA817+FrJ7GTc/VK2N6JSXu9KaVoDg4Sg=";
    })
  ];
  source.dirs."packages/modules/Virtualization".patches = [
    (fetchpatch {
      name = "ImageArchive: allow sdcard images even when os is not debuggable.patch";
      url = "https://github.com/GrapheneOS/platform_packages_modules_Virtualization/pull/5.patch";
      hash = "sha256-hru78WppRuNKWIbqrRQdm86Y8fuuZcPmM6MYXfS6Lmw=";
    })
  ];
  source.dirs."packages/apps/ExactCalculator" = lib.mkForce {
    src = sources.lineage_exactcalculator.src;
  };
  source.dirs."packages/apps/DeskClock" = lib.mkForce {
    src = sources.lineage_deskclock.src;
  };
  # cannot see Gallery from home screen with this:
  /*
    source.dirs."packages/apps/Gallery2" = lib.mkForce {
      src = pkgs.fetchFromGitHub {
        owner = "LineageOS";
        repo = "android_packages_apps_Gallery2";
        rev = "cce97b43244c7089839d710aa45dd2e64a94586e";
        hash = "sha256-QylzofyyciaoK2xHbSLZH7QdJOHVjzeH3vi35u3RD7g=";
      };
    };
  */
  source.dirs."packages/apps/Gallery2".patches = [
    (fetchpatch {
      name = "Remove references to Google in some translations";
      url = "https://github.com/GrapheneOS/platform_packages_apps_Gallery2/pull/14.patch";
      hash = "sha256-aO41dAmULosxYoas0ZwLTBShpfMBIKhLBKKCHkcAxNg=";
    })
  ];
  source.dirs."packages/inputmethods/LatinIME" = lib.mkForce {
    src = sources.lineage_latinime.src;
  };
  source.dirs."external/Info".postPatch = replace_app "Info" "apk_grapheneos-info";
  source.dirs."external/Camera".postPatch = replace_app "Camera" "apk_grapheneos-camera";
  source.dirs."external/AppStore".postPatch = replace_app "app-release" "apk_appstore";
  source.dirs."external/PdfViewer".postPatch = replace_app "PdfViewer" "apk_pdfviewer";
  source.dirs."packages/modules/Connectivity".patches = [
    (fetchpatch {
      name = "Connectivity: Add capability to allow tethering to use VPN upstreams";
      url = "https://github.com/LineageOS/android_packages_modules_Connectivity/commit/a365cfb8b6919aaa5ca99dafbc79ad95098ae218.patch";
      hash = "sha256-TrvrKyFWSBdZaYATDLffoQKI6EOYUGcPGeFxM654p7s=";
    })
  ];

  source.dirs."vendor/adevtool".patches = [
    ./adevtool-bigger-zram.patch # changing here is no effect but mightbe needed somewhere??
    ./adevtool-100p-4G.patch
  ];
  /*
    preBuild = ''
      set -e
      pwd
      cd "vendor/google_devices/${config.device}"
      [ ! -f proprietary/vendor/etc/fstab.zram.100p ]
      [ -f proprietary/vendor/etc/fstab.zram.50p ]
      cp proprietary/vendor/etc/fstab.zram.50p proprietary/vendor/etc/fstab.zram.100p
      substituteInPlace proprietary/vendor/etc/fstab.zram.100p --replace-fail "zramsize=50%" "size=100%"
      substituteInPlace proprietary/vendor/etc/fstab.zram.100p --replace-fail "zram_backingdev_size=1G" "zram_backingdev_size=4G"
      sed -i 's|vendor.zram.size=50p|vendor.zram.size=100p|' sysprop/vendor.prop
      cd -
    '';
  */

  source.dirs."bootable/recovery".patches = [
    (fetchpatch {
      name = "recovery: Enable the menu for User builds";
      url = "https://github.com/LineageOS/android_bootable_recovery/commit/0e5fd009ce1f8bcb681f6bfb2590ebc70734ea6a.patch";
      hash = "sha256-BZuXJ9xhp70TUbS5/bt6ihvLfmezc6tazDM9uM9Ahe0=";
    })
    /*
      # not useful for grapheneos
      (fetchpatch {
        name = "recovery: Expose reboot to recovery option";
        url = "https://github.com/LineageOS/android_bootable_recovery/commit/a27249584cbc29b6c2d1444ffa62f6377d9546bc.patch";
        hash = "sha256-/S3jLQ0LcXwQzuD5G9iskf9Qtmm7ICsDA+QIcUJo30M=";
      })
    */
    ./spl_downgrade.patch
  ];

  source.dirs."packages/apps/GmsCompat".patches = [
    (fetchpatch {
      name = "gmscompat: Make missing play games notification blockable";
      url = "https://github.com/GrapheneOS/platform_packages_apps_GmsCompat/pull/274.diff";
      hash = "sha256-+UXX1FjtlWCCXgt0qC2QDJ5xqTFYME5NGefaLBvD/ls=";
    })
  ];
}
