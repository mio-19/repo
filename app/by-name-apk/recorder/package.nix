{
  mk-apk-package,
  sources,
  lib,
  jdk21,
  gradle-packages,
  stdenv,
  apksigner,
  writableTmpDirAsHomeHook,
  androidSdkBuilder,
  ...
}:
let
  inherit (sources.lineage_recorder)
    src
    version
    ;

  appPackage =
    let
      androidSdk = androidSdkBuilder (s: [
        s.cmdline-tools-latest
        s.platform-tools
        s.platforms-android-36
        s.build-tools-35-0-0
      ]);

      gradle =
        (gradle-packages.mkGradle {
          version = "9.1.0";
          hash = "sha256-oX3dhaJran9d23H/iwX8UQTAICxuZHgkKXkMkzaGyAY=";
          defaultJava = jdk21;
        }).wrapped;
    in
    stdenv.mkDerivation (finalAttrs: {
      pname = "recorder";
      inherit version src;

      gradleBuildTask = ":app:assembleRelease";
      gradleUpdateTask = finalAttrs.gradleBuildTask;

      mitmCache = gradle.fetchDeps {
        inherit (finalAttrs) pname;
        pkg = finalAttrs.finalPackage;
        data = "recorder_deps.json";
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
        ANDROID_AAPT2_FROM_MAVEN_OVERRIDE = "${androidSdk}/share/android-sdk/build-tools/35.0.0/aapt2";
      };

      preConfigure = ''
        export ANDROID_USER_HOME="$HOME/.android"
        mkdir -p "$ANDROID_USER_HOME"
        echo "sdk.dir=${androidSdk}/share/android-sdk" > local.properties
      '';

      gradleFlags = [
        "-xlintVitalRelease"
        "-Dorg.gradle.java.installations.auto-download=false"
        "-Dorg.gradle.java.installations.paths=${jdk21}"
        "-Dandroid.aapt2FromMavenOverride=${androidSdk}/share/android-sdk/build-tools/35.0.0/aapt2"
        "-Dorg.gradle.project.android.aapt2FromMavenOverride=${androidSdk}/share/android-sdk/build-tools/35.0.0/aapt2"
      ];

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
    });
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
