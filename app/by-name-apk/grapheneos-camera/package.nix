{
  mk-apk-package,
  sources,
  lib,
  jdk21,
  jdk17,
  gradle-packages,
  stdenv,
  apksigner,
  writableTmpDirAsHomeHook,
  androidSdkBuilder,
  fetchpatch,
}:
let
  inherit (sources.grapheneos_camera)
    src
    version
    ;

  appPackage =
    let
      androidSdk = androidSdkBuilder (s: [
        s.cmdline-tools-latest
        s.platform-tools
        s.platforms-android-36
        s.build-tools-36-1-0
      ]);

      gradle =
        (gradle-packages.mkGradle {
          version = "9.4.0";
          hash = "sha256-YOpyM1bYEmPoAC/sD8+eKw7uDAhQx6PXqwpj8szGAfM=";
          defaultJava = jdk21;
        }).wrapped;
    in
    stdenv.mkDerivation (finalAttrs: {
      pname = "grapheneos-camera";
      inherit version src;

      patches = [
        (fetchpatch {
          name = "Add swipe haptics";
          url = "https://github.com/GrapheneOS/Camera/pull/351.patch";
          hash = "sha256-H/mU1tF/GgIMwnEpF5OKbp3u1J+cFBK8cKbB3cb7nA4=";
        })
        (fetchpatch {
          name = "Replace orientation API calls with sensor calculated orientation";
          url = "https://github.com/GrapheneOS/Camera/pull/535.patch";
          hash = "sha256-P4T5aKouSxAA0Q53vO6kJLputt3bSiPzR9EHwX8alSc=";
        })
        (fetchpatch {
          name = "Support beginning a video recording with the microphone muted";
          url = "https://github.com/GrapheneOS/Camera/pull/553.patch";
          hash = "sha256-QU/69Ugl8BQhwoYcs1izA9reRqcUi0/6sX8YzPr9yMg=";
        })
      ];

      gradleBuildTask = ":app:assembleRelease";
      gradleUpdateTask = finalAttrs.gradleBuildTask;

      mitmCache = gradle.fetchDeps {
        inherit (finalAttrs) pname;
        pkg = finalAttrs.finalPackage;
        data = ./grapheneos_camera_deps.json;
        silent = false;
        useBwrap = false;
      };

      nativeBuildInputs = [
        gradle
        jdk21
        jdk17
        apksigner
        writableTmpDirAsHomeHook
      ];

      env = {
        JAVA_HOME = if stdenv.isDarwin then "${jdk21}" else "${jdk21}/lib/openjdk";
        ANDROID_HOME = "${androidSdk}/share/android-sdk";
        ANDROID_SDK_ROOT = "${androidSdk}/share/android-sdk";
        ANDROID_AAPT2_FROM_MAVEN_OVERRIDE = "${androidSdk}/share/android-sdk/build-tools/36.1.0/aapt2";
      };

      preConfigure = ''
        export ANDROID_USER_HOME="$HOME/.android"
        mkdir -p "$ANDROID_USER_HOME"
        echo "sdk.dir=${androidSdk}/share/android-sdk" > local.properties
      '';

      gradleFlags =
        let
          postfix = if stdenv.isDarwin then "" else "/lib/openjdk";
        in
        [
          "-Dorg.gradle.java.installations.auto-download=false"
          "-Dorg.gradle.java.installations.paths=${jdk17}${postfix},${jdk21}${postfix}"
          "-Dandroid.aapt2FromMavenOverride=${androidSdk}/share/android-sdk/build-tools/36.1.0/aapt2"
          "-Dorg.gradle.project.android.aapt2FromMavenOverride=${androidSdk}/share/android-sdk/build-tools/36.1.0/aapt2"
        ];

      installPhase = ''
        runHook preInstall
        apk_path="$(echo app/build/outputs/apk/release/*-unsigned.apk)"
        install -Dm644 "$apk_path" "$out/Camera.apk"
        runHook postInstall
      '';

      meta = with lib; {
        description = "GrapheneOS Camera app (unsigned APK)";
        homepage = "https://github.com/GrapheneOS/Camera";
        license = licenses.mit;
        platforms = platforms.unix;
      };
    });
in
mk-apk-package {
  inherit appPackage;
  mainApk = "Camera.apk";
  signScriptName = "sign-grapheneos-camera";
}
