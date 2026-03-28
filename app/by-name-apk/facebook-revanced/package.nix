{ callPackage, raw }:
callPackage ../mk-apk-package.nix {
  appPackage = raw.facebook-revanced;
  mainApk = "facebook-revanced.apk";
  signScriptName = "sign-facebook-revanced";
  fdroid = {
    appId = "com.facebook.katana";
    metadataYml = ''
      Categories:
        - Internet
      License: Proprietary
      SourceCode: https://github.com/ReVanced/revanced-patches
      IssueTracker: https://github.com/ReVanced/revanced-patches/issues
      AutoName: Facebook ReVanced
      Summary: Patched Facebook APK
      Description: |-
        Facebook ReVanced is a patched Facebook APK built with
        ReVanced patches and kept under the original package name.
    '';
  };
}
