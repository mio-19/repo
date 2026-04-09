{
  mk-apk-package,
  lib,
  jdk25,
  gradle-packages,
  stdenv,
  fetchFromGitHub,
  apksigner,
  writableTmpDirAsHomeHook,
  androidSdkBuilder,
}:
let
  rev = "e076c26092496f3d16eeb4026daae5957658fddc";
  gradleFlavor = "Basic";
  releaseFlavor = "standard";

  appPackage =
    let
      androidSdk = androidSdkBuilder (s: [
        s.cmdline-tools-latest
        s.platform-tools
        s.platforms-android-36
        s.build-tools-35-0-1
        s.build-tools-36-1-0
      ]);

      gradle =
        (gradle-packages.mkGradle {
          version = "9.4.1";
          hash = "sha256-KrKVjyoeURIMMmytbzhRU7sR7pOzwhbF/M6/37t+xss=";
          defaultJava = jdk25;
        }).wrapped;
    in
    stdenv.mkDerivation (finalAttrs: {
      pname = "breezy-weather";
      version = "unstable-2026-04-06";

      src = fetchFromGitHub {
        owner = "breezy-weather";
        repo = "breezy-weather";
        inherit rev;
        hash = "sha256-13PNSrbdc+CFG9KKQmeXrnbE4K+tFGFVxRIpKoYEdK0=";
      };

      patches = [
        ./0001-disable-official-signature-checks.patch
      ];

      # Upstream's user-facing Standard release is the internal Gradle "basic" flavor.
      gradleBuildTask = ":app:assemble${gradleFlavor}Release";
      gradleUpdateTask = finalAttrs.gradleBuildTask;

      mitmCache = gradle.fetchDeps {
        inherit (finalAttrs) pname;
        pkg = finalAttrs.finalPackage;
        data = ./breezy-weather_deps.json;
        silent = false;
        useBwrap = false;
      };

      nativeBuildInputs = [
        gradle
        jdk25
        apksigner
        writableTmpDirAsHomeHook
      ];

      env = {
        JAVA_HOME = jdk25;
        ANDROID_HOME = "${androidSdk}/share/android-sdk";
        ANDROID_SDK_ROOT = "${androidSdk}/share/android-sdk";
        ANDROID_AAPT2_FROM_MAVEN_OVERRIDE = "${androidSdk}/share/android-sdk/build-tools/35.0.1/aapt2";
      };

      postPatch = ''
        substituteInPlace buildSrc/src/main/kotlin/breezy/buildlogic/Commands.kt \
          --replace-fail 'return runCommand("git rev-list --count HEAD")' 'return "60104"' \
          --replace-fail 'return runCommand("git rev-parse --short=8 HEAD")' 'return "${lib.substring 0 8 rev}"'

        echo "breezy.openweather.key=$(echo ZDljOTEwM2E3NGE0MzhlYWMwOTUyYTM0ZDFiNTgwZTYK | base64 -d)" >> local.properties
        echo "breezy.mf.key=$(echo X19XajdkVlNUalY5WUd1MWd1dmVMeURxMGc3UzdUZlRqYUhCVFBUcE8wa2o4X18K | base64 -d)" >> local.properties
        echo "breezy.mf.jwtKey=$(echo ODRhMzhkYjhjZGQ2NjJhMjY0MmY1MjZmMTE1ODhlN2UK | base64 -d)" >> local.properties
        echo "breezy.accu.key=$(echo NDY2YTRhOTVlMmE5NDgzZThmM2ZjMjJkOWJiMjM5NWYK | base64 -d)" >> local.properties
        echo "breezy.aemet.key=$(echo ZXlKaGJHY2lPaUpJVXpJMU5pSjkuZXlKemRXSWlPaUpoY0dsQVluSmxaWHA1ZDJWaGRHaGxjaTV2Y21jaUxDSnFkR2tpT2lJMlltUTFNVGxrWWkxbFkyVmlMVFExTVdVdE9EUXhNeTFrWkRjNU9EaGpaak14WlRVaUxDSnBjM01pT2lKQlJVMUZWQ0lzSW1saGRDSTZNVGN6TWpjeU5EVXdOeXdpZFhObGNrbGtJam9pTm1Ka05URTVaR0l0WldObFlpMDBOVEZsTFRnME1UTXRaR1EzT1RnNFkyWXpNV1UxSWl3aWNtOXNaU0k2SWlKOS5rUWtqMXRySmw3QkowNmtOdjZDSDN2LWpnWmRrVVVEa1Z5VHdISzBpMlhJCg== | base64 -d)" >> local.properties
        echo "breezy.atmoaura.key=$(echo ZTEzOWVkNDFmODEyMzgzZWQ4ODY3OGY4ZTdmYTc0NGYK | base64 -d)" >> local.properties
        echo "breezy.atmofrance.key=$(echo M2JlMmVjYjFhNThxNmd1eTY4NDVmNWo2OWE5ZDlkaDYK | base64 -d)" >> local.properties
        echo "breezy.atmograndest.key=$(echo MXw4d3JJNTNPWlBkUUdvaGdtb0Jrd0o0U1ZWVlhzQklBYWpubE1RSXo4Cg== | base64 -d)" >> local.properties
        echo "breezy.atmohdf.key=$(echo ZjE3MmQwZGEtZWFmMS00YTllLTg3YWYtYWEzYzZlM2U5YTcwCg== | base64 -d)" >> local.properties
        echo "breezy.atmosud.key=$(echo OTM3MWU0Zjk1NTA5MzEwZjY2ZGJhMDg3ZjJmNDY1ZGMK | base64 -d)" >> local.properties
        echo "breezy.baiduip.key=$(echo R00xZXZ1bG92R041RTQxcDZOQzcyTFczcWw1ZDBuTkcK | base64 -d)" >> local.properties
        echo "breezy.bmkg.key=$(echo ZXlKaGJHY2lPaUpJVXpJMU5pSXNJblI1Y0NJNklrcFhWQ0o5LmV5SnBaQ0k2SWpGak5XRmtaV1V4WXpZNU16TTBOalkyTjJFelpXTTBNV1JsTWpCbVpXWmhORGN4T1ROall6Y3laRGd3TUdSaU4yWm1abUZsTVdWaFlqY3haR1l5WWpRaUxDSnBZWFFpT2pFM01ERTFPRE16TnpsOS5EMVZOcE1vVFVWRk9VdVFXMHkydlNqdHRad2owc0tCWDMzS3lya2FSTWNRCg== | base64 -d)" >> local.properties
        echo "breezy.cwa.key=$(echo Q1dBLUM5ODdERkFBLTdEREUtNEU1OS1CMjgxLTVEQjBEOTgwRDI3MQo= | base64 -d)" >> local.properties
        echo "breezy.eccc.key=$(echo YTNjNjE5MmEtMjA0OC00NTMyLThjYjgtZGY3Y2FkOTNmYmYyCg== | base64 -d)" >> local.properties
        echo "breezy.geonames.key=$(echo YnJlZXp5d2VhdGhlcgo= | base64 -d)" >> local.properties
        echo "breezy.metie.key=$(echo ZXlKMGVYQWlPaUpLVjFRaUxDSmhiR2NpT2lKSVV6STFOaUo5LmV5SnBjM01pT2lKdFpYUXRhbmQwSWl3aWMzVmlJam94TENKcFlYUWlPakUxTWpnNE1USTJNRFVzSW1WNGNDSTZOemd6TmpBeE1qWXdOWDAuTVpTQkRrU1JHMnVXZ1hfVVZLX1BhMk9mdzFMeGpVczF6Sks3TnkwM3NCUQo= | base64 -d)" >> local.properties
      '';

      preConfigure = ''
        export ANDROID_USER_HOME="$HOME/.android"
        mkdir -p "$ANDROID_USER_HOME"
        echo "sdk.dir=${androidSdk}/share/android-sdk" >> local.properties
      '';

      gradleFlags = [
        # Select upstream's official Breezy branding resources instead of res_fork.
        "-Pbreezy"
        "-Dorg.gradle.java.installations.auto-download=false"
        "-Dorg.gradle.java.installations.paths=${jdk25}"
        "-Dandroid.aapt2FromMavenOverride=${androidSdk}/share/android-sdk/build-tools/35.0.1/aapt2"
        "-Dorg.gradle.project.android.aapt2FromMavenOverride=${androidSdk}/share/android-sdk/build-tools/35.0.1/aapt2"
      ];

      installPhase = ''
        runHook preInstall
        install -Dm644 \
          app/build/outputs/apk/${lib.toLower gradleFlavor}/release/app-${lib.toLower gradleFlavor}-universal-release-unsigned.apk \
          "$out/breezy-weather-${releaseFlavor}.apk"
        runHook postInstall
      '';

      meta = with lib; {
        description = "Breezy Weather app built from source (standard flavor)";
        homepage = "https://github.com/breezy-weather/breezy-weather";
        license = licenses.lgpl3Only;
        platforms = platforms.unix;
      };
    });
in
mk-apk-package {
  inherit appPackage;
  mainApk = "breezy-weather-${releaseFlavor}.apk";
  signScriptName = "sign-breezy-weather";
  fdroid = {
    appId = "org.breezyweather";
    metadataYml = ''
      Categories:
        - Internet
        - Wallpaper
        - Weather
      License: LGPL-3.0-only
      SourceCode: https://github.com/breezy-weather/breezy-weather
      IssueTracker: https://github.com/breezy-weather/breezy-weather/issues
      Translation: https://hosted.weblate.org/projects/breezy-weather/breezy-weather-android/#information
      Changelog: https://github.com/breezy-weather/breezy-weather/releases
      AutoName: Breezy Weather
      Summary: Feature-rich weather app with many data sources
      Description: |-
        Breezy Weather is a free/libre weather app with many forecast sources,
        air quality, widgets, and live wallpaper support.
        This package builds the upstream Standard flavor from source.
    '';
  };
}
