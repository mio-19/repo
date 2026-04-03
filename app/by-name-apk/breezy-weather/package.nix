{
  mk-apk-package,
  lib,
  jdk21,
  gradle-packages,
  stdenv,
  fetchFromGitHub,
  apksigner,
  writableTmpDirAsHomeHook,
  androidSdkBuilder,
}:
let
  rev = "2841817b95579e26d80f9a99179b6115e7b01802";

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
          defaultJava = jdk21;
        }).wrapped;
    in
    stdenv.mkDerivation (finalAttrs: {
      pname = "breezy-weather";
      version = "unstable-2026-03-29";

      src = fetchFromGitHub {
        owner = "breezy-weather";
        repo = "breezy-weather";
        inherit rev;
        hash = "sha256-c0gmlvg/4ONPYhWSJopX29wgjZdvSsxpR31WkRKIQ8A=";
      };

      gradleBuildTask = ":app:assembleBasicRelease";
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
        jdk21
        apksigner
        writableTmpDirAsHomeHook
      ];

      env = {
        JAVA_HOME = jdk21;
        ANDROID_HOME = "${androidSdk}/share/android-sdk";
        ANDROID_SDK_ROOT = "${androidSdk}/share/android-sdk";
        ANDROID_AAPT2_FROM_MAVEN_OVERRIDE = "${androidSdk}/share/android-sdk/build-tools/35.0.1/aapt2";
      };

      postPatch = ''
        substituteInPlace buildSrc/src/main/kotlin/breezy/buildlogic/Commands.kt \
          --replace-fail 'return runCommand("git rev-list --count HEAD")' 'return "60104"' \
          --replace-fail 'return runCommand("git rev-parse --short=8 HEAD")' 'return "${lib.substring 0 8 rev}"'

        substituteInPlace app/src/main/java/org/breezyweather/ui/main/MainActivity.kt \
          --replace-fail '        if (BreezyWeather.instance.isImpersonatingBreezyWeather) {' '        if (false) {' \
          --replace-fail '            LicenseComplianceDialog.show(this)' '            viewModel.checkToUpdate()'
      '';

      preConfigure = ''
        export ANDROID_USER_HOME="$HOME/.android"
        mkdir -p "$ANDROID_USER_HOME"
        echo "sdk.dir=${androidSdk}/share/android-sdk" > local.properties
      '';

      gradleFlags = [
        "-Dorg.gradle.java.installations.auto-download=false"
        "-Dorg.gradle.java.installations.paths=${jdk21}"
        "-Dandroid.aapt2FromMavenOverride=${androidSdk}/share/android-sdk/build-tools/35.0.1/aapt2"
        "-Dorg.gradle.project.android.aapt2FromMavenOverride=${androidSdk}/share/android-sdk/build-tools/35.0.1/aapt2"
      ];

      installPhase = ''
        runHook preInstall
        install -Dm644 \
          app/build/outputs/apk/basic/release/app-basic-universal-release-unsigned.apk \
          "$out/breezy-weather.apk"
        runHook postInstall
      '';

      meta = with lib; {
        description = "Breezy Weather app built from source (basic flavor)";
        homepage = "https://github.com/breezy-weather/breezy-weather";
        license = licenses.lgpl3Only;
        platforms = platforms.unix;
      };
    });
in
mk-apk-package {
  inherit appPackage;
  mainApk = "breezy-weather.apk";
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
        This package builds the upstream basic flavor from source.
    '';
  };
}
