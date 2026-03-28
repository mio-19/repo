{ callPackage, raw }:
callPackage ../mk-apk-package.nix {
  appPackage = raw.droidspaces-oss;
  mainApk = "droidspaces-oss.apk";
  signScriptName = "sign-droidspaces-oss";
  fdroid = {
    appId = "com.droidspaces.app";
    metadataYml = ''
      Categories:
        - System
      License: GPL-3.0-only
      SourceCode: https://github.com/ravindu644/Droidspaces-OSS
      IssueTracker: https://github.com/ravindu644/Droidspaces-OSS/issues
      AutoName: Droidspaces
      Summary: Containerized Linux workspace plus terminal for Android
      Description: |-
        Droidspaces launches pre-configured Linux containers, terminals,
        and utilities directly on Android. The build here matches upstream
        source artifacts.
    '';
  };
}
