{ callPackage, raw }:
callPackage ../mk-apk-package.nix {
  appPackage = raw.duolingo-revanced;
  mainApk = "duolingo-revanced.apk";
  signScriptName = "sign-duolingo-revanced";
  fdroid = {
    appId = "com.duolingo";
    metadataYml = ''
      Categories:
        - Internet
      License: Proprietary
      SourceCode: https://github.com/ReVanced/revanced-patches
      IssueTracker: https://github.com/ReVanced/revanced-patches/issues
      AutoName: Duolingo ReVanced
      Summary: Patched Duolingo APK
      Description: |-
        Duolingo ReVanced is a patched Duolingo APK built with ReVanced
        patches and kept under the original package name.
    '';
  };
}
