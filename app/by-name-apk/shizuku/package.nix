{ callPackage, raw }:
callPackage ../mk-apk-package.nix {
  appPackage = raw.shizuku;
  mainApk = "shizuku.apk";
  signScriptName = "sign-shizuku";
  fdroid = {
    appId = "moe.shizuku.privileged.api";
    metadataYml = ''
      Categories:
        - System
      License: Apache-2.0
      SourceCode: https://github.com/rikkaapps/shizuku
      IssueTracker: https://github.com/rikkaapps/shizuku/issues
      AutoName: Shizuku
      Summary: Run privileged APIs via a user-service bridge
      Description: |-
        Shizuku provides a bridge to use system-level APIs from apps
        without requiring root for every operation.
        This package is built from source.
    '';
  };
}
