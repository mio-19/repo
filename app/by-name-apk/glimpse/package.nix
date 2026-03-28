{ callPackage, raw }:
callPackage ../mk-apk-package.nix {
  appPackage = raw.glimpse;
  mainApk = "glimpse.apk";
  signScriptName = "sign-glimpse";
  fdroid = {
    appId = "org.lineageos.glimpse";
    metadataYml = ''
      Categories:
        - Photography
      License: Apache-2.0
      SourceCode: https://github.com/LineageOS/android_packages_apps_Glimpse
      IssueTracker: https://github.com/LineageOS/android_packages_apps_Glimpse/issues
      AutoName: Glimpse
      Summary: LineageOS Glimpse photo gallery
      Description: |-
        Glimpse is the default photo gallery app for LineageOS, built from source.
    '';
  };
}
