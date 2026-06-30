{
  mk-apk-package,
  lib,
  jdk21_headless,
  stdenv,
  fetchFromGitHub,

  writableTmpDirAsHomeHook,
  androidSdkBuilder,
  gradle,
  gradle_9_4_1,
}:
let
  appPackage = stdenv.mkDerivation (finalAttrs: {
    pname = "weathermaster";
    version = "3.6.0";

    src = fetchFromGitHub {
      owner = "PranshulGG";
      repo = "WeatherMaster";
      tag = "v${finalAttrs.version}";
      hash = "sha256-yLV5HUQYDJ9Al62XV0a60k6EYhnY/pS6dhV/CStQV+o=";
    };
    patches = [ ];

    postPatch = ''
      substituteInPlace app/build.gradle.kts \
        --replace-fail '            signingConfig = signingConfigs.getByName("release")' \
                       '            // Signing is handled by the Nix/F-Droid packaging flow.'
    '';

    androidSdk = androidSdkBuilder (s: [
      s.cmdline-tools-latest
      s.platform-tools
      s.platforms-android-34
      s.platforms-android-35
      s.platforms-android-36
      s.platforms-android-37-0
      s.build-tools-34-0-0
      s.build-tools-35-0-0
      s.build-tools-36-0-0
      s.build-tools-36-1-0
      s.build-tools-37-0-0
    ]);

    gradleBuildTask = ":app:assembleRelease";
    gradleUpdateTask = finalAttrs.gradleBuildTask;

    mitmCache = gradle.fetchDeps {
      inherit (finalAttrs) pname;
      pkg = finalAttrs.finalPackage;
      data = ./weathermaster_deps.json;
      silent = false;
      useBwrap = false;
    };

    nativeBuildInputs = [
      gradle_9_4_1
      jdk21_headless

      writableTmpDirAsHomeHook
    ];

    env = {
      JAVA_HOME = jdk21_headless.passthru.home;
      ANDROID_HOME = "${finalAttrs.androidSdk}/share/android-sdk";
      ANDROID_SDK_ROOT = "${finalAttrs.androidSdk}/share/android-sdk";
      ANDROID_AAPT2_FROM_MAVEN_OVERRIDE = "${finalAttrs.androidSdk}/share/android-sdk/build-tools/36.1.0/aapt2";
      GEO_NAMES_USERNAME = "dummy";
    };

    preConfigure = ''
      export ANDROID_USER_HOME="$HOME/.android"
      mkdir -p "$ANDROID_USER_HOME"
      echo "sdk.dir=${finalAttrs.androidSdk}/share/android-sdk" > local.properties
      echo "GEO_NAMES_USERNAME=dummy" >> local.properties

      if [ ! -f "$ANDROID_USER_HOME/debug.keystore" ]; then
        keytool -genkeypair \
          -alias androiddebugkey \
          -keyalg RSA \
          -keysize 2048 \
          -validity 10000 \
          -storetype JKS \
          -keystore "$ANDROID_USER_HOME/debug.keystore" \
          -storepass android \
          -keypass android \
          -dname "CN=Android Debug,O=Android,C=US"
      fi
    '';

    gradleFlags = [
      "-xlintVitalRelease"
      "-x"
      "checkReleaseAarMetadata"
      "-Dorg.gradle.java.installations.auto-download=false"
      "-Dorg.gradle.java.installations.paths=${jdk21_headless.passthru.home}"
      "-Dandroid.aapt2FromMavenOverride=${finalAttrs.androidSdk}/share/android-sdk/build-tools/36.1.0/aapt2"
      "-Dorg.gradle.project.android.aapt2FromMavenOverride=${finalAttrs.androidSdk}/share/android-sdk/build-tools/36.1.0/aapt2"
    ];

    installPhase = ''
      runHook preInstall
      apk_path=""
      for candidate in \
        app/build/outputs/apk/release/app-release-unsigned.apk \
        app/build/outputs/apk/release/app-release.apk; do
        if [ -f "$candidate" ]; then
          apk_path="$candidate"
          break
        fi
      done
      [ -n "$apk_path" ]
      install -Dm644 "$apk_path" "$out/weathermaster.apk"
      runHook postInstall
    '';

    meta = with lib; {
      description = "WeatherMaster weather app for Android built from source";
      homepage = "https://github.com/PranshulGG/WeatherMaster";
      license = licenses.gpl3Only;
      platforms = platforms.unix;
    };
  });
in
mk-apk-package {
  inherit appPackage;
  mainApk = "weathermaster.apk";
  signScriptName = "sign-weathermaster";
  fdroid = {
    appId = "com.pranshulgg.weather_master_app";
    metadataYml = ''
      Categories:
        - Science & Education
      License: GPL-3.0-only
      SourceCode: https://github.com/PranshulGG/WeatherMaster
      IssueTracker: https://github.com/PranshulGG/WeatherMaster/issues
      Changelog: https://github.com/PranshulGG/WeatherMaster/releases
      AutoName: WeatherMaster
      Summary: Weather app inspired by Pixel Weather
      Description: |-
        WeatherMaster is a weather app inspired by Google Pixel Weather.
        This package is built from source.
    '';
  };
}
