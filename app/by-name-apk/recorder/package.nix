{ callPackage, raw }:
callPackage ../mk-apk-package.nix {
  appPackage = raw.recorder;
  mainApk = "recorder.apk";
  signScriptName = "sign-recorder";
  fdroid = {
    appId = "org.lineageos.recorder";
    metadataYml = ''
      Categories:
        - Multimedia
      License: Apache-2.0
      SourceCode: https://github.com/LineageOS/android_packages_apps_Recorder
      IssueTracker: https://github.com/LineageOS/android_packages_apps_Recorder/issues
      AutoName: Recorder
      Summary: LineageOS screen and audio recorder
      Description: |-
        Recorder is the LineageOS app for recording audio and screen.
        This package is built from source.
    '';
  };
}
