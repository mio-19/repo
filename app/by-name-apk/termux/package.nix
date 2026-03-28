{ callPackage, raw }:
callPackage ../mk-apk-package.nix {
  appPackage = raw.termux;
  mainApk = "termux.apk";
  signScriptName = "sign-termux";
  fdroid = {
    appId = "com.termux";
    metadataYml = ''
      Categories:
        - Development
      License: GPL-3.0-only
      WebSite: https://termux.com
      SourceCode: https://github.com/termux/termux-app
      IssueTracker: https://github.com/termux/termux-app/issues
      Changelog: https://github.com/termux/termux-app/releases
      Donate: https://termux.com/donate.html
      OpenCollective: Termux
      AutoName: Termux
      Summary: Terminal emulator with Linux packages
      Description: |-
        Termux combines terminal emulation with a Linux package collection.
        This package is built from source from the upstream termux-app
        repository and follows the F-Droid universal APK build approach.
    '';
  };
}
