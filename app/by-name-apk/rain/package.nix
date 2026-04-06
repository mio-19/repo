{
  mk-apk-package,
  lib,
  buildDartApplication,
  runCommand,
  fetchFromGitHub,
  flutter338,
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
        s.platforms-android-34
        s.platforms-android-35
        s.platforms-android-36
        s.build-tools-34-0-0
        s.build-tools-35-0-0
        s.build-tools-36-1-0
        s.ndk-29-0-14206865
        s.cmake-3-31-6
      ]);

      gradle =
        (gradle-packages.mkGradle {
          version = "8.13";
          hash = "sha256-IPGxF2I3JUpvwgTYQ0GW+hGkz7OHVnUZxhVW6HEK7Xg=";
          defaultJava = jdk17_headless;
        }).wrapped;

      pythonWithYaml = python3.withPackages (ps: [ ps.pyyaml ]);
    in
    buildDartApplication.override { dart = flutter338; } (finalAttrs: {
      pname = "rain";
      version = "1.3.9-unstable-20260402";

      src = fetchFromGitHub {
        owner = "darkmoonight";
        repo = "Rain";
        rev = "8ac2440f1bb628996621bce459161ae51dd8ee41";
        hash = "sha256-MHn71xBdb5YRVl+BmirGB7jFQaPEfpd87GWzJaFZZgE=";
      };

      patches = [
        ./0001-nolint.patch
      ];

      pubspecLock = lib.importJSON ./pubspec.lock.json;
      gitHashes = lib.importJSON ./git-hashes.json;

      sdkSourceBuilders = {
        flutter =
          name:
          runCommand "flutter-sdk-${name}" { passthru.packageRoot = "."; } ''
            for path in \
              '${flutter338}/packages/${name}' \
              '${flutter338}/bin/cache/pkg/${name}'; do
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
        data = ./rain_deps.json;
        silent = false;
        useBwrap = false;
      };

      gradleUpdateTask = ":app:checkReleaseAarMetadata :app:assembleRelease :connectivity_plus:extractReleaseAnnotations :dynamic_color:checkReleaseAarMetadata :workmanager_android:checkReleaseAarMetadata";

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
        ANDROID_AAPT2_FROM_MAVEN_OVERRIDE = "${androidSdk}/share/android-sdk/build-tools/35.0.0/aapt2";
      };

      sdkSetupScript = ''
        flutter config --no-analytics >/dev/null 2>&1 || true
      '';

      gradleFlags = [
        "--project-dir"
        "android"
        "-Dorg.gradle.java.installations.auto-download=false"
        "-Dorg.gradle.java.installations.paths=${jdk17_headless}"
        "-Dandroid.aapt2FromMavenOverride=${androidSdk}/share/android-sdk/build-tools/35.0.0/aapt2"
        "-Dorg.gradle.project.android.aapt2FromMavenOverride=${androidSdk}/share/android-sdk/build-tools/35.0.0/aapt2"
      ];

      postPatch = ''
        cp -LR ${flutter338} flutter-sdk
        chmod -R u+w flutter-sdk
        : > flutter-sdk/bin/cache/engine.realm

        cat > android/gradlew << 'GRADLEW_SCRIPT'
        #!/bin/sh
        exec ${gradle}/bin/gradle "$@"
        GRADLEW_SCRIPT
        chmod +x android/gradlew

        if grep -Fq 'android.newDsl=true' android/gradle.properties; then
          substituteInPlace android/gradle.properties \
            --replace-fail 'android.newDsl=true' 'android.newDsl=false'
        elif ! grep -Fq 'android.newDsl=' android/gradle.properties; then
          echo 'android.newDsl=false' >> android/gradle.properties
        fi
        if grep -Fq 'signingConfig = signingConfigs.release' android/app/build.gradle; then
          substituteInPlace android/app/build.gradle \
            --replace-fail 'signingConfig = signingConfigs.release' 'signingConfig = signingConfigs.debug'
        fi

      '';

      preConfigure = ''
        export ANDROID_USER_HOME="$HOME/.android"
        mkdir -p "$ANDROID_USER_HOME"

        echo "sdk.dir=${androidSdk}/share/android-sdk" > android/local.properties
        echo "cmake.dir=${androidSdk}/share/android-sdk/cmake/3.31.6" >> android/local.properties
        echo "flutter.sdk=$PWD/flutter-sdk" >> android/local.properties
      '';

      preBuild = ''
        GRADLE_OPTS="''${GRADLE_OPTS:-}"
        GRADLE_OPTS="$GRADLE_OPTS -Dorg.gradle.java.installations.auto-download=false"
        GRADLE_OPTS="$GRADLE_OPTS -Dorg.gradle.java.installations.paths=${jdk17_headless}"
        GRADLE_OPTS="$GRADLE_OPTS -Dandroid.aapt2FromMavenOverride=${androidSdk}/share/android-sdk/build-tools/35.0.0/aapt2"
        GRADLE_OPTS="$GRADLE_OPTS -Dorg.gradle.project.android.aapt2FromMavenOverride=${androidSdk}/share/android-sdk/build-tools/35.0.0/aapt2"
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
          "$out/rain.apk"
        runHook postInstall
      '';

      meta = with lib; {
        description = "Rain weather app for Android built from source";
        homepage = "https://github.com/darkmoonight/Rain";
        license = licenses.mit;
        platforms = platforms.unix;
      };
    });
in
mk-apk-package {
  inherit appPackage;
  mainApk = "rain.apk";
  signScriptName = "sign-rain";
  fdroid = {
    appId = "com.yoshi.rain";
    metadataYml = ''
      Categories:
        - Science & Education
      License: MIT
      SourceCode: https://github.com/darkmoonight/Rain
      IssueTracker: https://github.com/darkmoonight/Rain/issues
      AutoName: Rain
      Summary: Weather forecast app
      Description: |-
        Rain is a weather forecast app with current, hourly, and weekly weather
        views, location search, widgets, and notifications.
        This package is built from source.
    '';
  };
}
