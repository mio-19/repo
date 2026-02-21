args@{
  config,
  pkgs,
  lib,
  ...
}:
{
  buildDateTime = 1771647233;
  flavor = "grapheneos";
  grapheneos.channel = "alpha";
  source.dirs."frameworks/base".patches = with pkgs; [
    #./No-gestural-navigation-hint-bar.patch

    #./Disable-FLAG_SECURE.patch
    # https://github.com/GrapheneOS/os-issue-tracker/issues/664#issuecomment-3937125786
    (fetchpatch {
      url = "https://github.com/GrapheneOS/platform_frameworks_base/pull/313.patch";
      hash = "sha256-lC8YVoxb7ATdPhY/JPlNRgay0yOkJxUFnVNIN/6AiE4=";
    })

    (fetchpatch {
      name = "Add toggle to hide location access indicator on a per-app basis.patch";
      url = "https://github.com/GrapheneOS/platform_frameworks_base/pull/305.patch";
      hash = "sha256-oJnWjITM4pycHQRbLORQTmr9315LXtGk8Upzi2IRONU=";
    })
  ];
  source.dirs."packages/apps/Settings".patches = with pkgs; [
    # https://github.com/GrapheneOS/os-issue-tracker/issues/664#issuecomment-3937125786
    (fetchpatch {
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
    (fetchpatch {
      name = "Launcher3: Add hasNavigationBar() check.patch";
      url = "https://github.com/VoltageOS/packages_apps_Launcher3/commit/bdd98e87d1438e13f95ad4992071ef44fd931695.patch";
      hash = "sha256-Ke0NsftuKxJrDTyAZdj4tOrInNDf2aA2gRd1rs84dsk=";
    })
    (fetchpatch {
      name = "Launcher3: Do not wrap icons from icon pack";
      url = "https://github.com/VoltageOS/packages_apps_Launcher3/commit/f64b5c694b1b5feee9e77f3dd87c221fccd8eab1.patch";
      hash = "sha256-B75RY2QPeU0vtAWC2+DH9udi4n5lHhpFtfROyE6PqRg=";
    })
    (fetchpatch {
      name = "Launcher3: Hide scrollbar when searching All Apps";
      url = "https://github.com/VoltageOS/packages_apps_Launcher3/commit/8f2bb1a5685bc043e4b52d7a79291994f8a32078.patch";
      hash = "sha256-ukOdTP5Ks91d5Q8aGjF0h/6tdM2HCHc5vScbtx9CaCk=";
    })
  ];
  source.dirs."packages/apps/ExactCalculator" = lib.mkForce {
    src = pkgs.fetchFromGitHub {
      owner = "LineageOS";
      repo = "android_packages_apps_ExactCalculator";
      rev = "f80bf9cd59dff2a7f628157482cdb54a9509613a";
      hash = "sha256-3Y+3g4IcURRirzdvGpG9o78wInTqTAd1zHGKK2sgUv4=";
    };
  };
}
