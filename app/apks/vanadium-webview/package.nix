{
  mk-apk-package,
  sources,
  lib,
  stdenvNoCC,
}:

let
  appPackage = stdenvNoCC.mkDerivation {
    pname = "vanadium-webview";
    version = sources.grapheneos_vanadium.date;
    src = sources.grapheneos_vanadium.src;
    dontUnpack = true;
    installPhase = ''
      mkdir -p $out
      cp $src/prebuilt/arm64/VanadiumWebView.apk $out/VanadiumWebView.apk
    '';
  };
in
mk-apk-package {
  inherit appPackage;
  mainApk = "VanadiumWebView.apk";
  signScriptName = "sign-vanadium-webview";
  fdroid = {
    appId = "app.vanadium.webview";
    preSigned = true;
    metadataYml = ''
      Categories:
        - System
      License: BSD-3-Clause
      SourceCode: https://github.com/GrapheneOS/Vanadium
      AutoName: Vanadium WebView
      Summary: Privacy and security focused Chromium-based WebView
      Description: |-
        Vanadium WebView is a privacy and security focused Chromium-based WebView
        developed by GrapheneOS.
    '';
  };
}
