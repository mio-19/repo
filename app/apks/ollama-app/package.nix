{
  mk-apk-package,
  lib,
  buildDartApplication,
  runCommand,
  fetchFromGitHub,
  flutter329,
  jdk17_headless,
  python3,
  gradle-packages,
  writableTmpDirAsHomeHook,
  androidSdkBuilder,
}:
let
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

      gradle =
        (gradle-packages.mkGradle {
          version = "8.10.2";
          hash = "sha256-McVXE+QCM6gwOCfOtCykikcmegrUurkXcSMSHnFSTCY=";
          defaultJava = jdk17_headless;
        }).wrapped;
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
        flutter =
          name:
          runCommand "flutter-sdk-${name}" { passthru.packageRoot = "."; } ''
            for path in \
              '${flutter329}/packages/${name}' \
              '${flutter329}/bin/cache/pkg/${name}'; do
              if [ -d "$path" ]; then
                ln -s "$path" "$out"
                break
              fi
            done
            if [ ! -e "$out" ]; then
              echo 1>&2 'The Flutter SDK does not contain the requested package: ${name}!'
              exit 1
            fi
          '';
      };

      mitmCache = gradle.fetchDeps {
        inherit (finalAttrs) pname;
        pkg = finalAttrs.finalPackage;
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
        JAVA_HOME = jdk17_headless;
        ANDROID_HOME = "${androidSdk}/share/android-sdk";
        ANDROID_SDK_ROOT = "${androidSdk}/share/android-sdk";
        ANDROID_NDK_HOME = "${androidSdk}/share/android-sdk/ndk/27.0.12077973";
        ANDROID_NDK_ROOT = "${androidSdk}/share/android-sdk/ndk/27.0.12077973";
        ANDROID_AAPT2_FROM_MAVEN_OVERRIDE = "${androidSdk}/share/android-sdk/build-tools/36.0.0/aapt2";
      };

      sdkSetupScript = ''
        flutter config --no-analytics >/dev/null 2>&1 || true
      '';

      gradleFlags = [
        "--project-dir"
        "android"
        "-Dorg.gradle.java.installations.auto-download=false"
        "-Dorg.gradle.java.installations.paths=${jdk17_headless}"
        "-Dandroid.aapt2FromMavenOverride=${androidSdk}/share/android-sdk/build-tools/36.0.0/aapt2"
        "-Dorg.gradle.project.android.aapt2FromMavenOverride=${androidSdk}/share/android-sdk/build-tools/36.0.0/aapt2"
      ];

      postPatch = ''
        cp -LR ${flutter329} flutter-sdk
        chmod -R u+w flutter-sdk
        touch flutter-sdk/bin/cache/engine.realm # https://github.com/NixOS/nixpkgs/pull/500309#issuecomment-4192628176

        cat > android/gradlew << 'GRADLEW_SCRIPT'
        #!/bin/sh
        exec ${gradle}/bin/gradle "$@"
        GRADLEW_SCRIPT
        chmod +x android/gradlew
      '';

      preConfigure = ''
        export ANDROID_USER_HOME="$HOME/.android"
        mkdir -p "$ANDROID_USER_HOME"
        echo "sdk.dir=${androidSdk}/share/android-sdk" > android/local.properties
        echo "cmake.dir=${androidSdk}/share/android-sdk/cmake/3.22.1" >> android/local.properties
        echo "ndk.dir=${androidSdk}/share/android-sdk/ndk/27.0.12077973" >> android/local.properties
        echo "flutter.sdk=$PWD/flutter-sdk" >> android/local.properties
        echo "flutter.versionName=1.2.0" >> android/local.properties
        echo "flutter.versionCode=9" >> android/local.properties
      '';

      preBuild = ''
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
        GRADLE_OPTS="$GRADLE_OPTS -Dorg.gradle.java.installations.paths=${jdk17_headless}"
        GRADLE_OPTS="$GRADLE_OPTS -Dandroid.aapt2FromMavenOverride=${androidSdk}/share/android-sdk/build-tools/36.0.0/aapt2"
        GRADLE_OPTS="$GRADLE_OPTS -Dorg.gradle.project.android.aapt2FromMavenOverride=${androidSdk}/share/android-sdk/build-tools/36.0.0/aapt2"
        if [[ -n "''${MITM_CACHE_KEYSTORE:-}" ]]; then
          GRADLE_OPTS="$GRADLE_OPTS -Dhttp.proxyHost=$MITM_CACHE_HOST"
          GRADLE_OPTS="$GRADLE_OPTS -Dhttp.proxyPort=$MITM_CACHE_PORT"
          GRADLE_OPTS="$GRADLE_OPTS -Dhttps.proxyHost=$MITM_CACHE_HOST"
          GRADLE_OPTS="$GRADLE_OPTS -Dhttps.proxyPort=$MITM_CACHE_PORT"
          GRADLE_OPTS="$GRADLE_OPTS -Djavax.net.ssl.trustStore=$MITM_CACHE_KEYSTORE"
          GRADLE_OPTS="$GRADLE_OPTS -Djavax.net.ssl.trustStorePassword=$MITM_CACHE_KS_PWD"
        fi
        export FLUTTER_ROOT="$PWD/flutter-sdk"
        export GRADLE_OPTS

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
