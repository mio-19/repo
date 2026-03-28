{ callPackage, raw }:
callPackage ../mk-apk-package.nix {
  appPackage = raw.thunderbird;
  mainApk = "thunderbird.apk";
  signScriptName = "sign-thunderbird";
  fdroid = {
    appId = "net.thunderbird.android";
    metadataYml = ''
      Categories:
        - Internet
      License: Apache-2.0
      SourceCode: https://github.com/thunderbird/thunderbird-android
      IssueTracker: https://github.com/thunderbird/thunderbird-android/issues
      AutoName: Thunderbird
      Summary: Thunderbird for Android (foss flavor)
      Description: |-
        Thunderbird is a free, open-source email client. This is the F-Droid
        foss flavor built from the THUNDERBIRD_17_0 branch without any
        proprietary Google dependencies.
    '';
  };
}
