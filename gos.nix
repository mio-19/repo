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
}
