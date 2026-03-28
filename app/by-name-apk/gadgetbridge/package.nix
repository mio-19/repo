{ callPackage, raw }:
callPackage ../mk-apk-package.nix {
  appPackage = raw.gadgetbridge;
  mainApk = "gadgetbridge.apk";
  signScriptName = "sign-gadgetbridge";
  fdroid = {
    appId = "nodomain.freeyourgadget.gadgetbridge";
    metadataYml = ''
      Categories:
        - Connectivity
        - Health & Fitness
      License: Apache-2.0
      WebSite: https://gadgetbridge.org/
      SourceCode: https://codeberg.org/Freeyourgadget/Gadgetbridge
      IssueTracker: https://codeberg.org/Freeyourgadget/Gadgetbridge/issues
      Changelog: https://codeberg.org/Freeyourgadget/Gadgetbridge/releases
      AutoName: Gadgetbridge
      Summary: Companion app for wearable devices
      Description: |-
        Gadgetbridge is a libre companion app for wearable devices.

        This package is built from source and follows the current
        F-Droid mainline build, including the Fossil HR asset build step.
    '';
  };
}
