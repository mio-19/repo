{ callPackage, raw }:
callPackage ../mk-apk-package.nix {
  appPackage = raw.haven;
  mainApk = "haven.apk";
  signScriptName = "sign-haven";
  fdroid = {
    appId = "sh.haven.app";
    metadataYml = ''
      Categories:
        - Internet
        - System
      License: GPL-3.0-only
      SourceCode: https://github.com/GlassOnTin/Haven
      IssueTracker: https://github.com/GlassOnTin/Haven/issues
      AutoName: Haven
      Summary: SSH/Mosh terminal and Reticulum network client
      Description: |-
        Haven is an SSH/Mosh terminal and Reticulum network client for Android,
        featuring end-to-end encrypted messaging via the Reticulum stack.
        This package is built from source (arm64).
    '';
  };
}
