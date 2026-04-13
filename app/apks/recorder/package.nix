{
  mk-apk-package,
  overrides-fromsrc,
  buildGradlePackage,
  sources,
  lib,
  jdk25_headless,
  gradle-packages,

  writableTmpDirAsHomeHook,
  androidSdkBuilder,
  overrides-fromsrc-updated,
  gradle_9_1_0,
}:
let
  inherit (sources.lineage_recorder)
    src
    version
    ;

  androidSdk = androidSdkBuilder (s: [
    s.cmdline-tools-latest
    s.platform-tools
    s.platforms-android-36
    s.build-tools-35-0-0
  ]);

  gradle = gradle_9_1_0;

  appPackage = buildGradlePackage rec {
    pname = "recorder";
    inherit version src gradle;

    lockFile = ./gradle.lock;
    overrides = overrides-fromsrc-updated;
    buildJdk = jdk25_headless;

    nativeBuildInputs = [
      androidSdk
      gradle
      jdk25_headless

      writableTmpDirAsHomeHook
    ];

    dontUseGradleConfigure = true;

    env = {
      ANDROID_HOME = "${androidSdk}/share/android-sdk";
      ANDROID_SDK_ROOT = "${androidSdk}/share/android-sdk";
      ANDROID_AAPT2_FROM_MAVEN_OVERRIDE = "${androidSdk}/share/android-sdk/build-tools/35.0.0/aapt2";
    };

    preConfigure = ''
      export ANDROID_USER_HOME="$HOME/.android"
      export GRADLE_USER_HOME="$(mktemp -d)"
      export TERM=dumb
      mkdir -p "$ANDROID_USER_HOME"
      echo "sdk.dir=${androidSdk}/share/android-sdk" > local.properties
      gradleFlagsArray+=(--no-daemon --init-script "$gradleInitScript" --offline)
    '';

    gradleFlags = [
      "-x"
      "lintVitalRelease"
      "-Dorg.gradle.java.home=${jdk25_headless.home}"
      "-Dorg.gradle.java.installations.auto-download=false"
      "-Dorg.gradle.java.installations.paths=${jdk25_headless}"
      "-Dandroid.aapt2FromMavenOverride=${androidSdk}/share/android-sdk/build-tools/35.0.0/aapt2"
      "-Dorg.gradle.project.android.aapt2FromMavenOverride=${androidSdk}/share/android-sdk/build-tools/35.0.0/aapt2"
    ];

    gradleBuildFlags = ":app:assembleRelease";

    installPhase = ''
      runHook preInstall
      apk_path="$(echo app/build/outputs/apk/release/*-release-unsigned.apk)"
      install -Dm644 "$apk_path" "$out/recorder.apk"
      runHook postInstall
    '';

    meta = with lib; {
      description = "LineageOS Recorder app";
      homepage = "https://github.com/LineageOS/android_packages_apps_Recorder";
      license = licenses.asl20;
      platforms = platforms.unix;
    };
  };
in
mk-apk-package {
  inherit appPackage;
  mainApk = "recorder.apk";
  signScriptName = "sign-recorder";
  fdroid = {
    appId = "org.lineageos.recorder";
    metadataYml = ''
      Categories:
        - Multimedia
      License: Apache-2.0
      SourceCode: https://github.com/LineageOS/android_packages_apps_Recorder
      IssueTracker: https://github.com/LineageOS/android_packages_apps_Recorder/issues
      AutoName: Recorder
      Summary: LineageOS screen and audio recorder
      Description: |-
        Recorder is the LineageOS app for recording audio and screen.
        This package is built from source.
    '';
  };
}
