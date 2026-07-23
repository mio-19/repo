{
  mk-apk-package,
  lib,
  buildDartApplication,
  runCommand,
  fetchFromGitHub,
  flutter329,
  jdk17_headless,
  python3,
  gradle_8_10_2,
  writableTmpDirAsHomeHook,
  androidSdkBuilder,
}:
let
  flutterApkHelpers = ../_shared/flutter-apk-helpers.sh;
  mkFlutterSdkSourceBuilder = import ../_shared/mk-flutter-sdk-source-builder.nix;

  appPackage =
    let
      androidSdk = androidSdkBuilder (s: [
        s.cmdline-tools-latest
        s.platform-tools
        s.platforms-android-31
        s.platforms-android-32
        s.platforms-android-33
        s.platforms-android-34
        s.platforms-android-35
        s.platforms-android-36
        s.build-tools-34-0-0
        s.build-tools-35-0-0
        s.build-tools-36-0-0
        s.ndk-27-0-12077973
        s.cmake-3-22-1
      ]);

      gradle = gradle_8_10_2;
      androidSdkRoot = "${androidSdk}/share/android-sdk";
      aapt2 = "${androidSdkRoot}/build-tools/36.0.0/aapt2";
      ndkVersion = "27.0.12077973";
      pythonWithYaml = python3.withPackages (ps: [ ps.pyyaml ]);
    in
    buildDartApplication.override { dart = flutter329; } (finalAttrs: {
      pname = "ollama-app";
      version = "1.2.0+9";

      src = fetchFromGitHub {
        owner = "JHubi1";
        repo = "ollama-app";
        rev = "3759d32049771096b172b99400edae6d4f1a2557";
        hash = "sha256-zlXuVueUBA4y7ty/6P5pd2aeSCAL/FZbYJQr2CI8Aew=";
      };

      pubspecLock = lib.importJSON ./pubspec.lock.json;
      gitHashes = {
        flutter_tts = "sha256-XVqBZamrlJPoERArUeWEyWnNg99cbyMbn0M2lXoIWyE=";
      };

      sdkSourceBuilders = {
        flutter = mkFlutterSdkSourceBuilder {
          inherit runCommand;
          flutter = flutter329;
        };
      };

      mitmCache = gradle.fetchDeps {
        inherit (finalAttrs) pname;
        attrPath = "apk_ollama-app";
        pkg = finalAttrs.finalPackage;
        # removed master-index and group-index and play-sdk/index/snapshot.gz manually
        data = ./ollama-app_deps.json;
        silent = false;
        useBwrap = false;
      };

      gradleUpdateScript = ''
        runHook preBuild
        runHook preGradleUpdate
        flutter build apk --release --no-pub
        runHook postGradleUpdate
      '';

      dontDartBuild = true;
      dontDartInstall = true;

      nativeBuildInputs = [
        gradle
        jdk17_headless
        python3
        writableTmpDirAsHomeHook
      ];

      env = {
        JAVA_HOME = jdk17_headless.passthru.home;
        ANDROID_HOME = androidSdkRoot;
        ANDROID_SDK_ROOT = androidSdkRoot;
        ANDROID_NDK_HOME = "${androidSdkRoot}/ndk/${ndkVersion}";
        ANDROID_NDK_ROOT = "${androidSdkRoot}/ndk/${ndkVersion}";
        ANDROID_AAPT2_FROM_MAVEN_OVERRIDE = aapt2;
      };

      sdkSetupScript = ''
        flutter config --no-analytics >/dev/null 2>&1 || true
      '';

      gradleFlags = [
        "--project-dir"
        "android"
        "-Dorg.gradle.java.installations.auto-download=false"
        "-Dorg.gradle.java.installations.paths=${jdk17_headless.passthru.home}"
        "-Dandroid.aapt2FromMavenOverride=${aapt2}"
        "-Dorg.gradle.project.android.aapt2FromMavenOverride=${aapt2}"
      ];

      postPatch = ''
        . ${flutterApkHelpers}
        setup_writable_flutter_sdk ${flutter329}
        setup_pinned_gradlew ${gradle}/bin/gradle
      '';

      preConfigure = ''
        export ANDROID_USER_HOME="$HOME/.android"
        mkdir -p "$ANDROID_USER_HOME"
        {
          echo "sdk.dir=${androidSdkRoot}"
          echo "cmake.dir=${androidSdkRoot}/cmake/3.22.1"
          echo "ndk.dir=${androidSdkRoot}/ndk/${ndkVersion}"
          echo "flutter.sdk=$PWD/flutter-sdk"
          echo "flutter.versionName=1.2.0"
          echo "flutter.versionCode=9"
        } > android/local.properties
      '';

      preBuild = ''
        . ${flutterApkHelpers}

        printf '%s\n' \
          'storePassword=android' \
          'keyPassword=android' \
          'keyAlias=androiddebugkey' \
          'storeFile=../debug.keystore' > android/key.properties

        rm -f android/debug.keystore
        keytool -genkeypair -noprompt \
          -keystore android/debug.keystore \
          -storepass android \
          -keypass android \
          -alias androiddebugkey \
          -keyalg RSA \
          -keysize 2048 \
          -validity 10000 \
          -dname "CN=Android Debug,O=Android,C=US"

        GRADLE_OPTS="''${GRADLE_OPTS:-}"
        GRADLE_OPTS="$GRADLE_OPTS -Dorg.gradle.java.installations.auto-download=false"
        GRADLE_OPTS="$GRADLE_OPTS -Dorg.gradle.java.installations.paths=${jdk17_headless.passthru.home}"
        GRADLE_OPTS="$GRADLE_OPTS -Dandroid.aapt2FromMavenOverride=${aapt2}"
        GRADLE_OPTS="$GRADLE_OPTS -Dorg.gradle.project.android.aapt2FromMavenOverride=${aapt2}"
        append_mitm_gradle_opts
        export FLUTTER_ROOT="$PWD/flutter-sdk"

        ${pythonWithYaml}/bin/python3 ${../_shared/generate-flutter-plugins.py}
      '';

      buildPhase = ''
        runHook preBuild
        flutter build apk --release --no-pub
        runHook postBuild
      '';

      installPhase = ''
        runHook preInstall
        install -Dm644 build/app/outputs/flutter-apk/app-release.apk \
          "$out/ollama-app.apk"
        runHook postInstall
      '';

      meta = with lib; {
        description = "Modern Android client for Ollama built from source";
        homepage = "https://github.com/JHubi1/ollama-app";
        license = licenses.gpl3Plus;
        platforms = platforms.unix;
      };
    });
in
mk-apk-package {
  inherit appPackage;
  mainApk = "ollama-app.apk";
  signScriptName = "sign-ollama-app";
  fdroid = {
    appId = "com.freakurl.apps.ollama";
    metadataYml = ''
      Categories:
        - Internet
      License: GPL-3.0-or-later
      SourceCode: https://github.com/JHubi1/ollama-app
      IssueTracker: https://github.com/JHubi1/ollama-app/issues
      AutoName: Ollama App
      Summary: Android client for Ollama
      Description: |-
        Ollama App is a modern client for chatting with Ollama servers.
        This package is built from source.
    '';
  };
}
