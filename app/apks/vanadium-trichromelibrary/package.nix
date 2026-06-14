{
  mk-apk-package,
  sources,
  lib,
  stdenvNoCC,
}:

let
  appPackage = stdenvNoCC.mkDerivation {
    pname = "vanadium-trichromelibrary";
    version = sources.grapheneos_vanadium.date;
    src = sources.grapheneos_vanadium.src;
    dontUnpack = true;
    installPhase = ''
      mkdir -p $out
      cp $src/prebuilt/arm64/TrichromeLibrary.apk $out/TrichromeLibrary.apk
    '';
  };
in
mk-apk-package {
  inherit appPackage;
  mainApk = "TrichromeLibrary.apk";
  signScriptName = "sign-vanadium-trichromelibrary";
  fdroid = {
    appId = "org.chromium.trichromelibrary";
    preSigned = true;
    metadataYml = ''
      Categories:
        - System
      License: BSD-3-Clause
      SourceCode: https://github.com/GrapheneOS/Vanadium
      AutoName: Trichrome Library
      Summary: Shared library for Vanadium
      Description: |-
        Trichrome Library provides shared code for Vanadium Browser and WebView.
    '';
  };
}
