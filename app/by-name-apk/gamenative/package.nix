{
  mk-apk-package,
  lib,
  jdk17_headless,
  gradle-packages,
  stdenv,
  fetchFromGitHub,
  apksigner,
  writableTmpDirAsHomeHook,
  androidSdkBuilder,
}:
let
  appPackage =
    let
      androidSdk = androidSdkBuilder (s: [
        s.cmdline-tools-latest
        s.platform-tools
        s.platforms-android-35
        s.build-tools-35-0-0
      ]);

      gradle =
        (gradle-packages.mkGradle {
          version = "8.12.1";
          hash = "sha256-jZepeYT2y9K4X+TGCnQ0QKNHVEvxiBgEjmEfUojUbJQ=";
          defaultJava = jdk17_headless;
        }).wrapped;
    in
    stdenv.mkDerivation (finalAttrs: {
      pname = "gamenative";
      version = "0.8.1";

      src = fetchFromGitHub {
        owner = "utkarshdalal";
        repo = "GameNative";
        tag = "v${finalAttrs.version}";
        hash = "sha256-JvzIjfKqL/7Tqb0vqNhF5nS8FGawqJIc20wWuff1qJE=";
      };

      patches = [
        ./disable-release-lint.patch
        ./fix-dependency-resolution.patch
      ];

      postPatch = ''
        substituteInPlace app/build.gradle.kts \
          --replace-fail '    ndkVersion = "22.1.7171670"' ""
      '';

      gradleBuildTask = ":app:assembleRelease";
      gradleUpdateTask = finalAttrs.gradleBuildTask;

      mitmCache = gradle.fetchDeps {
        inherit (finalAttrs) pname;
        pkg = finalAttrs.finalPackage;
        data = ./gamenative_deps.json;
        silent = false;
        useBwrap = false;
      };

      nativeBuildInputs = [
        gradle
        jdk17_headless
        apksigner
        writableTmpDirAsHomeHook
      ];

      env = {
        JAVA_HOME = jdk17_headless;
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
        "-xlintVitalAnalyzeRelease"
        "-Dorg.gradle.java.installations.auto-download=false"
        "-Dorg.gradle.java.installations.paths=${jdk17_headless}"
        "-Dandroid.aapt2FromMavenOverride=${androidSdk}/share/android-sdk/build-tools/35.0.0/aapt2"
        "-Dorg.gradle.project.android.aapt2FromMavenOverride=${androidSdk}/share/android-sdk/build-tools/35.0.0/aapt2"
      ];

      installPhase = ''
        runHook preInstall
        apk_path="$(echo app/build/outputs/apk/release/*.apk | awk '{print $1}')"
        install -Dm644 "$apk_path" "$out/gamenative.apk"
        runHook postInstall
      '';

      meta = with lib; {
        description = "Android launcher for running Windows games";
        homepage = "https://github.com/utkarshdalal/GameNative";
        license = licenses.gpl3Only;
        platforms = platforms.unix;
      };
    });
in
mk-apk-package {
  inherit appPackage;
  mainApk = "gamenative.apk";
  signScriptName = "sign-gamenative";
  fdroid = {
    appId = "app.gamenative";
    metadataYml = ''
      Categories:
        - Games
      License: GPL-3.0-only
      SourceCode: https://github.com/utkarshdalal/GameNative
      IssueTracker: https://github.com/utkarshdalal/GameNative/issues
      Changelog: https://github.com/utkarshdalal/GameNative/releases
      AutoName: GameNative
      Summary: Android launcher for running Windows games
      Description: |-
        GameNative is an Android launcher for running Windows games with
        integrated container, Steam, and compatibility-layer management.
        This package is built from source.
    '';
  };
}
