{ callPackage, raw }:
callPackage ../mk-apk-package.nix {
  appPackage = raw.element-android;
  mainApk = "element-android.apk";
  signScriptName = "sign-element-android";
  fdroid = {
    appId = "im.vector.app";
    metadataYml = ''
      Categories:
        - Internet
      License: Apache-2.0
      SourceCode: https://github.com/element-hq/element-android
      IssueTracker: https://github.com/element-hq/element-android/issues
      AutoName: Element
      Summary: Secure Matrix messenger (F-Droid flavor)
      Description: |-
        Element is a Matrix-based end-to-end encrypted messenger and
        collaboration app. This is the F-Droid flavor built from source
        without proprietary Google services.
    '';
  };
}
