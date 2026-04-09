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
  appPackage =
    let
      androidSdk = androidSdkBuilder (s: [
        s.cmdline-tools-latest
        s.platform-tools
        # compileSdkVersion 31 in apk/build.gradle.
        s.platforms-android-31
        # AGP 8.7.3 resolves aapt2 from build-tools 34.0.0 by default.
        s.build-tools-34-0-0
      ]);

      gradle =
        (gradle-packages.mkGradle {
          version = "8.9";
          hash = "sha256-1yXXB7+r1N/clYxiQAOzyArMwD9wN7USLEsdDvFc7Ks=";
          defaultJava = jdk25;
        }).wrapped;
    in
    stdenv.mkDerivation (finalAttrs: {
      pname = "tuxguitar-android";
      version = "2.0.1";

      src = fetchFromGitHub {
        owner = "helge17";
        repo = "tuxguitar";
        rev = finalAttrs.version;
        hash = "sha256-USdYj8ebosXkiZpDqyN5J+g1kjyWm225iQlx/szXmLA=";
      };

      gradleBuildTask = "assembleRelease";
      gradleUpdateTask = finalAttrs.gradleBuildTask;

      postPatch = ''
        substituteInPlace android/build-scripts/tuxguitar-android/apk/build.gradle \
          --replace-fail \
            'versionName "9.99-SNAPSHOT"' \
            'versionName "${finalAttrs.version}"' \
          --replace-fail \
            "versionCode Integer.parseInt(new Date().format('yyMMddHH'))" \
            'versionCode 20001'
      '';

      # Lock refresh steps:
      # 1. If TuxGuitar bumps Gradle, update gradle.version and gradle.hash.
      # 2. Build the updater:
      #    nix build --impure .#tuxguitar-android.mitmCache.updateScript
      # 3. Run the resulting fetch-deps.sh from the repo root to regenerate
      #    app/tuxguitar/tuxguitar_deps.json.
      mitmCache = gradle.fetchDeps {
        inherit (finalAttrs) pname;
        pkg = finalAttrs.finalPackage;
        data = ./tuxguitar_deps.json;
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
        ANDROID_AAPT2_FROM_MAVEN_OVERRIDE = "${androidSdk}/share/android-sdk/build-tools/34.0.0/aapt2";
      };

      # The Gradle project root lives in a subdirectory of the monorepo.
      # cd there so gradlew and settings.gradle are found; subsequent phases
      # (build, install) inherit this working directory.
      preConfigure = ''
        export ANDROID_USER_HOME="$HOME/.android"
        mkdir -p "$ANDROID_USER_HOME"
        echo "sdk.dir=${androidSdk}/share/android-sdk" \
          > android/build-scripts/tuxguitar-android/local.properties
        cd android/build-scripts/tuxguitar-android
      '';

      gradleFlags = [
        "-xlintVitalRelease"
        "-Dorg.gradle.java.installations.auto-download=false"
        "-Dorg.gradle.java.installations.paths=${jdk25}"
        "-Dandroid.aapt2FromMavenOverride=${androidSdk}/share/android-sdk/build-tools/34.0.0/aapt2"
        "-Dorg.gradle.project.android.aapt2FromMavenOverride=${androidSdk}/share/android-sdk/build-tools/34.0.0/aapt2"
      ];

      installPhase = ''
        runHook preInstall
        install -Dm644 \
          apk/build/outputs/apk/release/tuxguitar-android-9.99-SNAPSHOT-release-unsigned.apk \
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
