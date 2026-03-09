args@{
  config,
  pkgs,
  pkgs-unstable,
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
  buildDateTime = 1772543347;
  flavor = "grapheneos";
  grapheneos.channel = "alpha";
  source.dirs."frameworks/base".patches = with pkgs; [
    #./No-gestural-navigation-hint-bar.patch

    #./Disable-FLAG_SECURE.patch
    # https://github.com/GrapheneOS/os-issue-tracker/issues/664#issuecomment-3937125786
    (fetchpatch {
      name = "Add a toggle to allow screenshots through FLAG SECURE";
      url = "https://github.com/GrapheneOS/platform_frameworks_base/pull/313.patch";
      hash = "sha256-S3zWY9AFAS2iKVPEl8p03HhidOxdKXs0BEG10jVxWZQ=";
    })

    (fetchpatch {
      # https://github.com/GrapheneOS/platform_frameworks_base/pull/305
      name = "Add toggle to hide location access indicator on a per-app basis.patch";
      url = "https://github.com/GrapheneOS/platform_frameworks_base/commit/751e18efce972f7f976bcc43d8fcc21469d26653.patch";
      hash = "sha256-oJnWjITM4pycHQRbLORQTmr9315LXtGk8Upzi2IRONU=";
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
  source.dirs."packages/apps/Settings".patches = with pkgs; [
    # https://github.com/GrapheneOS/os-issue-tracker/issues/664#issuecomment-3937125786
    (fetchpatch {
      name = "Add a toggle to disable FLAG SECURE";
      url = "https://github.com/GrapheneOS/platform_packages_apps_Settings/pull/411.patch";
      hash = "sha256-hcztYEyhfDlfkx04lKmsEOKr2puoM6GUb3bhRIgiCaM=";
    })
  ];
  source.dirs."packages/modules/Permission".patches = with pkgs; [
    (fetchpatch {
      name = "Add toggle to hide location access indicator on a per-app basis.patch";
      url = "https://github.com/GrapheneOS/platform_packages_modules_Permission/pull/83.patch";
      hash = "sha256-zyZS6vHgp2hHTGn7BUcaJcqkAo7SbbJmZmcPQN0kGOM=";
    })
  ];
  source.dirs."packages/apps/Dialer".patches = with pkgs; [
    # https://github.com/GrapheneOS/platform_packages_apps_Dialer/pull/48
    (fetchpatch {
      name = "Add automatic call recording.patch";
      url = "https://github.com/GrapheneOS/platform_packages_apps_Dialer/commit/4b2b28c36e3f0a29e2f7d171e9ae1128d54eb27c.patch";
      hash = "sha256-ceo+c99iyYeaweks1Hk/VYXl8pa3PMGtcbHcxOLRM4k=";
    })
  ];
  source.dirs."packages/apps/AppCompatConfig".patches = with pkgs; [
    (fetchpatch {
      name = "add configs for Brave beta and Brave nightly.patch";
      url = "https://github.com/GrapheneOS/platform_packages_apps_AppCompatConfig/pull/6.patch";
      hash = "sha256-QoabShVmthSA817+FrJ7GTc/VK2N6JSXu9KaVoDg4Sg=";
    })
  ];
  source.dirs."packages/modules/Virtualization".patches = with pkgs; [
    (fetchpatch {
      name = "ImageArchive: allow sdcard images even when os is not debuggable.patch";
      url = "https://github.com/GrapheneOS/platform_packages_modules_Virtualization/pull/5.patch";
      hash = "sha256-hru78WppRuNKWIbqrRQdm86Y8fuuZcPmM6MYXfS6Lmw=";
    })
  ];
  source.dirs."packages/apps/Launcher3".patches = with pkgs; [
    # cannot find symbol ENABLE_TASKBAR/NAVIGATION_BAR_HINT
    /*
      (fetchpatch {
        # from https://github.com/VoltageOS/packages_apps_Launcher3/commit/6a474287135cb6fc147379efd0c1bfc069f49efd
        name = "Launcher3: Implement taskbar toggle.patch";
        url = "https://github.com/mio-19/platform_packages_apps_Launcher3/commit/381899ea085f2a8f642b7aaebf74bef50daa6d60.patch";
        hash = "sha256-u2EpJIH0QDJuWhuKYjNSKE4GCCpd1FQwd5FnUtca6es=";
      })
      (fetchpatch {
        # from https://github.com/VoltageOS/packages_apps_Launcher3/commit/f445d2b4af7408bf56a168516d2e8c3c71b37cc6
        name = "Launcher3: Implement gesture hint toggle.patch";
        url = "https://github.com/mio-19/platform_packages_apps_Launcher3/commit/7480f89cb0f526d8fb667bfd4972cca826aa70b5.patch";
        hash = "sha256-wxgturb6mCY37A6QL4CAGuoFx9p1IPcAVmZlEtWC06k=";
      })
    */
    (fetchpatch {
      name = "Launcher3: Add hasNavigationBar() check.patch";
      url = "https://github.com/VoltageOS/packages_apps_Launcher3/commit/bdd98e87d1438e13f95ad4992071ef44fd931695.patch";
      hash = "sha256-Ke0NsftuKxJrDTyAZdj4tOrInNDf2aA2gRd1rs84dsk=";
    })
    # cannot find symbol CONFIG_HINT_NO_WRAP
    /*
      (fetchpatch {
        name = "Launcher3: Do not wrap icons from icon pack";
        url = "https://github.com/VoltageOS/packages_apps_Launcher3/commit/f64b5c694b1b5feee9e77f3dd87c221fccd8eab1.patch";
        hash = "sha256-B75RY2QPeU0vtAWC2+DH9udi4n5lHhpFtfROyE6PqRg=";
      })
    */
    (fetchpatch {
      name = "Launcher3: Hide scrollbar when searching All Apps";
      url = "https://github.com/VoltageOS/packages_apps_Launcher3/commit/8f2bb1a5685bc043e4b52d7a79291994f8a32078.patch";
      hash = "sha256-ukOdTP5Ks91d5Q8aGjF0h/6tdM2HCHc5vScbtx9CaCk=";
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
  source.dirs."packages/apps/Gallery2".patches = with pkgs; [
    (fetchpatch {
      name = "Remove references to Google in some translations";
      url = "https://github.com/GrapheneOS/platform_packages_apps_Gallery2/pull/14.patch";
      hash = "sha256-aO41dAmULosxYoas0ZwLTBShpfMBIKhLBKKCHkcAxNg=";
    })
  ];
  source.dirs."packages/inputmethods/LatinIME" = lib.mkForce {
    src = sources.lineage_latinime.src;
  };
  source.dirs."external/Info" = lib.mkForce {
    src = pkgs-unstable.callPackage ./grapheneos_info_app.nix { };
  };
  source.dirs."packages/modules/Connectivity".patches = with pkgs; [
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

  source.dirs."bootable/recovery".patches = with pkgs; [
    (fetchpatch {
      name = "recovery: Enable the menu for User builds";
      url = "https://github.com/LineageOS/android_bootable_recovery/commit/0e5fd009ce1f8bcb681f6bfb2590ebc70734ea6a.patch";
      hash = "sha256-BZuXJ9xhp70TUbS5/bt6ihvLfmezc6tazDM9uM9Ahe0=";
    })
    (fetchpatch {
      name = "recovery: Expose reboot to recovery option";
      url = "https://github.com/LineageOS/android_bootable_recovery/commit/a27249584cbc29b6c2d1444ffa62f6377d9546bc.patch";
      hash = "sha256-/S3jLQ0LcXwQzuD5G9iskf9Qtmm7ICsDA+QIcUJo30M=";
    })
    ./spl_downgrade.patch
  ];
}
