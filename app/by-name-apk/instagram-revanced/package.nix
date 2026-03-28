{ callPackage, raw }:
callPackage ../mk-apk-package.nix {
  appPackage = raw.instagram-revanced;
  mainApk = "instagram-revanced.apk";
  signScriptName = "sign-instagram-revanced";
  fdroid = {
    appId = "com.instagram.android";
    metadataYml = ''
      Categories:
        - Internet
      License: Proprietary
      SourceCode: https://github.com/ReVanced/revanced-patches
      IssueTracker: https://github.com/ReVanced/revanced-patches/issues
      AutoName: Instagram ReVanced
      Summary: Patched Instagram APK
      Description: |-
        Instagram ReVanced is a patched Instagram APK built with
        ReVanced patches and kept under the original package name.
    '';
  };
}
