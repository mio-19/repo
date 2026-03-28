{ callPackage, raw }:
callPackage ../mk-apk-package.nix {
  appPackage = raw.reddit-morphe;
  mainApk = "reddit-morphe.apk";
  signScriptName = "sign-reddit-morphe";
  fdroid = {
    appId = "com.reddit.frontpage.morphe";
    metadataYml = ''
      Categories:
        - Internet
      License: Proprietary
      SourceCode: https://github.com/MorpheApp/morphe-patches
      IssueTracker: https://github.com/MorpheApp/morphe-patches/issues
      AutoName: Reddit Morphe
      Summary: Patched Reddit APK with package rename
      Description: |-
        Reddit Morphe is a patched Reddit APK built with Morphe patches
        and installed under an alternate package name.
    '';
  };
}
