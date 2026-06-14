{
  mk-apk-package,
  sources,
  lib,
  stdenvNoCC,
}:

let
  appPackage = stdenvNoCC.mkDerivation {
    pname = "vanadium-browser";
    version = sources.grapheneos_vanadium.date;
    src = sources.grapheneos_vanadium.src;
    dontUnpack = true;
    installPhase = ''
      mkdir -p $out
      cp $src/prebuilt/arm64/TrichromeChrome.apk $out/TrichromeChrome.apk
    '';
  };
in
mk-apk-package {
  inherit appPackage;
  mainApk = "TrichromeChrome.apk";
  signScriptName = "sign-vanadium";
  fdroid = {
    appId = "app.vanadium.browser";
    preSigned = true;
    metadataYml = ''
      Categories:
        - System
      License: BSD-3-Clause
      SourceCode: https://github.com/GrapheneOS/Vanadium
      AutoName: Vanadium
      Summary: Privacy and security focused Chromium-based browser
      Description: |-
        Vanadium is a privacy and security focused Chromium-based browser
        developed by GrapheneOS.
    '';
  };
}
