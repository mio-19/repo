{ callPackage, raw }:
callPackage ../mk-apk-package.nix {
  appPackage = raw.tuxguitar-android;
  mainApk = "tuxguitar-android.apk";
  signScriptName = "sign-tuxguitar-android";
  fdroid = {
    appId = "app.tuxguitar.android.application";
    metadataYml = ''
      Categories:
        - Multimedia
      License: LGPL-2.1-or-later
      SourceCode: https://github.com/helge17/tuxguitar
      IssueTracker: https://github.com/helge17/tuxguitar/issues
      AutoName: TuxGuitar
      Summary: Multitrack guitar tablature editor
      Description: |-
        TuxGuitar is a multitrack guitar tablature editor and player.
        It can open GuitarPro, PowerTab, and TablEdit files.
    '';
  };
}
