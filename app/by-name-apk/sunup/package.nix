{ callPackage, raw }:
callPackage ../mk-apk-package.nix {
  appPackage = raw.sunup;
  mainApk = "sunup.apk";
  signScriptName = "sign-sunup";
  fdroid = {
    appId = "org.unifiedpush.distributor.sunup";
    metadataYml = ''
      Categories:
        - System
      License: GPL-3.0-or-later
      SourceCode: https://codeberg.org/Sunup/android
      IssueTracker: https://codeberg.org/Sunup/android/issues
      AutoName: Sunup
      Summary: UnifiedPush distributor using a local push gateway
      Description: |-
        Sunup is a UnifiedPush distributor that uses a local push gateway
        to deliver push notifications without relying on Google services.
        This package is built from source.
    '';
  };
}
