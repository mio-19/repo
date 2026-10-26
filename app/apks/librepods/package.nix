{
  mk-apk-package,
  lib,
  fetchurl,
  stdenvNoCC,
}:
let
  version = "1.0.4";
  apkFile = fetchurl {
    name = "LibrePods-v${version}.apk";
    url = "https://github.com/librepods-org/librepods/releases/download/v${version}/LibrePods-FOSS-v${version}-100040301-release.apk";
    hash = "sha256-gT4uUytFy2GEqHkIuQNuCYRmH4NKOWz3YZ1EP5t021Q=";
  };
  appPackage = stdenvNoCC.mkDerivation {
    pname = "librepods";
    inherit version;
    dontUnpack = true;
    installPhase = ''
      mkdir -p $out
      cp ${apkFile} $out/librepods.apk
    '';
  };
in
mk-apk-package {
  inherit appPackage;
  mainApk = "librepods.apk";
  signScriptName = "sign-librepods";
  fdroid = {
    appId = "me.kavishdevar.librepods";
    preSigned = true;
    metadataYml = ''
      Categories:
        - Audio
        - Connectivity
      License: GPL-3.0-only
      WebSite: https://librepods.org
      SourceCode: https://github.com/librepods-org/librepods
      AutoName: LibrePods
      Summary: AirPods companion app liberated from Apple's ecosystem
      Description: |-
        LibrePods brings Apple AirPods features to Android including
        noise cancellation, transparency mode, conversational awareness,
        adaptive audio, and battery reporting.
    '';
  };
}
