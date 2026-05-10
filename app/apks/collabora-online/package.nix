{
  mk-apk-package,
  lib,
  stdenv,
  fetchurl,
}:
let
  # Official prebuilt snapshot APK from Collabora
  appPackage = stdenv.mkDerivation {
    pname = "collabora-office-bin";
    version = "25.04-snapshot-2026-03-26";
    src = fetchurl {
      url = "https://www.collaboraoffice.com/downloads/Collabora-Office-Android-Snapshot/collabora-office-mobile-25.04-snapshot-arm64-v8a-2026-03-26.apk";
      hash = "sha256-Zl0nMQyghJi8ACwtkTTou7Jv1shKmhenDwUXFSH97/k=";
    };
    dontUnpack = true;
    installPhase = ''
      mkdir -p $out
      cp $src $out/collabora-online.apk
    '';
  };
in
mk-apk-package {
  inherit appPackage;
  mainApk = "collabora-online.apk";
  signScriptName = "sign-collabora-online";
  fdroid = {
    appId = "org.collabora.app";
    metadataYml = ''
      Categories:
        - Office
      License: MPL-2.0
      SourceCode: https://github.com/CollaboraOnline/online
      IssueTracker: https://github.com/CollaboraOnline/online/issues
      AutoName: Collabora Office
      Summary: Open source office suite based on LibreOffice
      Description: |-
        Collabora Office is a powerful office suite based on LibreOffice
        that allows you to edit documents, spreadsheets, and presentations.
        This package uses the official prebuilt snapshot binary.
    '';
  };
}
