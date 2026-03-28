{ callPackage, raw }:
callPackage ../mk-apk-package.nix {
  appPackage = raw.gamenative;
  mainApk = "gamenative.apk";
  signScriptName = "sign-gamenative";
  fdroid = {
    appId = "app.gamenative";
    metadataYml = ''
      Categories:
        - Games
      License: GPL-3.0-only
      SourceCode: https://github.com/utkarshdalal/GameNative
      IssueTracker: https://github.com/utkarshdalal/GameNative/issues
      Changelog: https://github.com/utkarshdalal/GameNative/releases
      AutoName: GameNative
      Summary: Android launcher for running Windows games
      Description: |-
        GameNative is an Android launcher for running Windows games with
        integrated container, Steam, and compatibility-layer management.
        This package is built from source.
    '';
  };
}
