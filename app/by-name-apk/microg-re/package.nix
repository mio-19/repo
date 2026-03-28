{ callPackage, raw }:
callPackage ../mk-apk-package.nix {
  appPackage = raw.microg-re;
  mainApk = "microg-re.apk";
  signScriptName = "sign-microg-re";
  fdroid = {
    appId = "app.revanced.android.gms";
    metadataYml = ''
      Categories:
        - System
      License: Apache-2.0
      SourceCode: https://github.com/MorpheApp/MicroG-RE
      IssueTracker: https://github.com/MorpheApp/MicroG-RE/issues
      AutoName: MicroG RE
      Summary: microG fork for patched Google apps
      Description: |-
        MicroG RE is a fork of microG GmsCore adapted for patched Google
        apps and distributed under an alternative package name.
        This package is built from source.
    '';
  };
}
