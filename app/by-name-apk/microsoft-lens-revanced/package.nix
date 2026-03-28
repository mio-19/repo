{ callPackage, raw }:
callPackage ../mk-apk-package.nix {
  appPackage = raw.microsoft-lens-revanced;
  mainApk = "microsoft-lens-revanced.apk";
  signScriptName = "sign-microsoft-lens-revanced";
  fdroid = {
    appId = "com.microsoft.office.officelens";
    metadataYml = ''
      Categories:
        - Productivity
      License: Proprietary
      SourceCode: https://github.com/ReVanced/revanced-patches
      IssueTracker: https://github.com/ReVanced/revanced-patches/issues
      AutoName: Microsoft Lens ReVanced
      Summary: Patched Microsoft Lens APK
      Description: |-
        Microsoft Lens ReVanced is a patched Microsoft Lens APK built
        with ReVanced patches and kept under the original package name.
    '';
  };
}
