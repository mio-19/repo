{
  mk-apk-package,
  lib,
  jdk21_headless,
  gradle_8_9,
  stdenv,
  fetchFromGitHub,

  writableTmpDirAsHomeHook,
  androidSdkBuilder,
}:
let
  appPackage =
    let
      androidSdk = androidSdkBuilder (s: [
        s.cmdline-tools-latest
        s.platform-tools
        # compileSdkVersion 35 in apk/build.gradle.
        s.platforms-android-35
        # AGP 8.7.3 resolves aapt2 from build-tools 34.0.0 by default.
        s.build-tools-34-0-0
        s.build-tools-35-0-0
      ]);

      gradle = gradle_8_9;
      androidSdkRoot = "${androidSdk}/share/android-sdk";
      aapt2 = "${androidSdkRoot}/build-tools/34.0.0/aapt2";
      jdkHome = jdk21_headless.passthru.home;
    in
    stdenv.mkDerivation (finalAttrs: {
      pname = "tuxguitar-android";
      version = "2.1.0";

      src = fetchFromGitHub {
        owner = "helge17";
        repo = "tuxguitar";
        # Prefer tag=; this project tags releases as bare version strings.
        tag = finalAttrs.version;
        hash = "sha256-JaR9gagVXgcf1bQ0v/9KO3SzqAXSpjJpCuCRQXs9Wzg=";
      };

      gradleBuildTask = "assembleRelease";
      gradleUpdateTask = finalAttrs.gradleBuildTask;

      # Lock refresh steps:
      # 1. If TuxGuitar bumps Gradle, update gradle.version and gradle.hash.
      # 2. Build the updater:
      #    nix build --impure .#apk_tuxguitar-android.mitmCache.updateScript
      # 3. Run the resulting fetch-deps.sh from the repo root to regenerate
      #    app/apks/tuxguitar-android/tuxguitar_deps.json.
      mitmCache = gradle.fetchDeps {
        inherit (finalAttrs) pname;
        attrPath = "apk_tuxguitar-android";
        pkg = finalAttrs.finalPackage;
        data = ./tuxguitar_deps.json;
        silent = false;
        useBwrap = false;
      };

      nativeBuildInputs = [
        gradle
        jdk21_headless

        writableTmpDirAsHomeHook
      ];

      env = {
        JAVA_HOME = jdkHome;
        ANDROID_HOME = androidSdkRoot;
        ANDROID_SDK_ROOT = androidSdkRoot;
        ANDROID_AAPT2_FROM_MAVEN_OVERRIDE = aapt2;
      };

      # The Gradle project root lives in a subdirectory of the monorepo.
      # cd there so gradlew and settings.gradle are found; subsequent phases
      # (build, install) inherit this working directory.
      preConfigure = ''
        export ANDROID_USER_HOME="$HOME/.android"
        mkdir -p "$ANDROID_USER_HOME"
        echo "sdk.dir=${androidSdkRoot}" \
          > android/build-scripts/tuxguitar-android/local.properties
        cd android/build-scripts/tuxguitar-android
      '';

      gradleFlags = [
        "-xlintVitalRelease"
        "-Dorg.gradle.java.installations.auto-download=false"
        "-Dorg.gradle.java.installations.paths=${jdkHome}"
        "-Dandroid.aapt2FromMavenOverride=${aapt2}"
        "-Dorg.gradle.project.android.aapt2FromMavenOverride=${aapt2}"
      ];

      installPhase = ''
        runHook preInstall
        install -Dm644 \
          apk/build/outputs/apk/release/tuxguitar-android-${finalAttrs.version}-release-unsigned.apk \
          "$out/tuxguitar-android.apk"
        runHook postInstall
      '';

      meta = with lib; {
        description = "TuxGuitar multitrack guitar tablature editor (Android, unsigned)";
        homepage = "https://github.com/helge17/tuxguitar";
        license = licenses.lgpl21Plus;
        platforms = platforms.unix;
      };
    });
in
mk-apk-package {
  inherit appPackage;
  mainApk = "tuxguitar-android.apk";
  signScriptName = "sign-tuxguitar-android";
  fdroid = {
    appId = "app.tuxguitar.android.application";
    metadataYml = ''
      Categories:
        - Multimedia
      License: LGPL-2.1-or-later
      SourceCode: https://github.com/helge17/tuxguitar
      IssueTracker: https://github.com/helge17/tuxguitar/issues
      AutoName: TuxGuitar
      Summary: Multitrack guitar tablature editor
      Description: |-
        TuxGuitar is a multitrack guitar tablature editor and player.
        It can open GuitarPro, PowerTab, and TablEdit files.
    '';
  };
}
