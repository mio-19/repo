{ callPackage, raw }:
callPackage ../mk-apk-package.nix {
  appPackage = raw.termux-x11;
  mainApk = "termux-x11.apk";
  signScriptName = "sign-termux-x11";
  fdroid = {
    appId = "com.termux.x11";
    metadataYml = ''
      Categories:
        - Development
      License: GPL-3.0-only
      WebSite: https://termux.com
      SourceCode: https://github.com/termux/termux-x11
      IssueTracker: https://github.com/termux/termux-x11/issues
      Changelog: https://github.com/termux/termux-x11/releases/tag/nightly
      Donate: https://termux.com/donate.html
      OpenCollective: Termux
      AutoName: Termux:X11
      Summary: X11 server add-on for Termux
      Description: |-
        Termux:X11 is the X11 server companion app for Termux.
        This package is built from source from the upstream master
        branch at commit 3376f0ed5f5c7cf4ba960df218a00c6cc053ffb7.

        F-Droid does not currently ship metadata for this application,
        so this repo follows the upstream nightly debug universal APK
        build layout instead.
    '';
  };
}
