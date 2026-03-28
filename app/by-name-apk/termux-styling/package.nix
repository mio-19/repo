{ callPackage, raw }:
callPackage ../mk-apk-package.nix {
  appPackage = raw.termux-styling;
  mainApk = "termux-styling.apk";
  signScriptName = "sign-termux-styling";
  fdroid = {
    appId = "com.termux.styling";
    metadataYml = ''
      Categories:
        - Development
      License: GPL-3.0-only
      WebSite: https://termux.com
      SourceCode: https://github.com/termux/termux-styling
      IssueTracker: https://github.com/termux/termux-styling/issues
      Changelog: https://github.com/termux/termux-styling/releases
      Donate: https://termux.com/donate.html
      OpenCollective: Termux
      AutoName: Termux:Styling
      Summary: Color schemes and fonts for Termux
      Description: |-
        This Termux plugin provides color schemes and powerline-ready fonts
        to customize the terminal appearance.
        This package is built from source from the upstream
        termux-styling GitHub repository at the latest commit after the
        0.32.1 F-Droid release.
    '';
  };
}
