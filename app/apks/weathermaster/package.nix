{
  mk-apk-package,
  lib,
  buildDartApplication,
  runCommand,
  fetchFromGitHub,
  flutter332,
  jdk17_headless,
  python3,
  gradle_8_12,
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
        s.build-tools-31-0-0
        s.build-tools-34-0-0
        s.build-tools-35-0-0
        s.build-tools-36-1-0
        s.ndk-27-0-12077973
        s.cmake-3-31-6
      ]);

      gradle = gradle_8_12;

      patchedFlutter = runCommand "flutter332-kotlin-dsl-patched" { } ''
        cp -LR ${flutter332} "$out"
        chmod -R u+w "$out"
        flutter_gradle_kts="$out/packages/flutter_tools/gradle/build.gradle.kts"
        if grep -Fq 'id("org.gradle.kotlin.kotlin-dsl") version "5.1.2"' "$flutter_gradle_kts"; then
          substituteInPlace "$flutter_gradle_kts" \
            --replace-fail 'id("org.gradle.kotlin.kotlin-dsl") version "5.1.2"' 'id("org.gradle.kotlin.kotlin-dsl") version "6.4.2"'
        elif grep -Fq 'id("org.gradle.kotlin.kotlin-dsl") version "5.2.0"' "$flutter_gradle_kts"; then
          substituteInPlace "$flutter_gradle_kts" \
            --replace-fail 'id("org.gradle.kotlin.kotlin-dsl") version "5.2.0"' 'id("org.gradle.kotlin.kotlin-dsl") version "6.4.2"'
        fi
      '';

      pythonWithYaml = python3.withPackages (ps: [ ps.pyyaml ]);
    in
    buildDartApplication.override { dart = patchedFlutter; } (finalAttrs: {
      pname = "weathermaster";
      version = "2.7.1";

      src = fetchFromGitHub {
        owner = "PranshulGG";
        repo = "WeatherMaster";
        tag = "v${finalAttrs.version}";
        hash = "sha256-oER5gPW4Hc+jH3cFTIRMhT54H5vKWsaur7/uY+21E4w=";
      };
      patches = [ ./disable-release-lint-and-signing.patch ];

      pubspecLock = lib.importJSON ./pubspec.lock.json;
      gitHashes = { };

      sdkSourceBuilders = {
        flutter =
          name:
          runCommand "flutter-sdk-${name}" { passthru.packageRoot = "."; } ''
            for path in \
              '${patchedFlutter}/packages/${name}' \
              '${patchedFlutter}/bin/cache/pkg/${name}'; do
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
        data = ./weathermaster_deps.json;
        silent = false;
        useBwrap = false;
      };

      gradleUpdateTask = ":app:assembleRelease";

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
        ANDROID_AAPT2_FROM_MAVEN_OVERRIDE = "${androidSdk}/share/android-sdk/build-tools/36.1.0/aapt2";
      };

      sdkSetupScript = ''
        flutter config --no-analytics >/dev/null 2>&1 || true
      '';

      gradleFlags = [
        "--project-dir"
        "android"
        "-Dandroid.builder.sdkDownload=false"
        "-Dorg.gradle.java.installations.auto-download=false"
        "-Dorg.gradle.java.installations.paths=${jdk17_headless}"
        "-Dandroid.aapt2FromMavenOverride=${androidSdk}/share/android-sdk/build-tools/36.1.0/aapt2"
        "-Dorg.gradle.project.android.aapt2FromMavenOverride=${androidSdk}/share/android-sdk/build-tools/36.1.0/aapt2"
      ];

      postPatch = ''
        cp -LR ${patchedFlutter} flutter-sdk
        chmod -R u+w flutter-sdk
        touch flutter-sdk/bin/cache/engine.realm # https://github.com/NixOS/nixpkgs/pull/500309#issuecomment-4192628176

        if grep -Fq 'id("org.gradle.kotlin.kotlin-dsl") version "5.1.2"' flutter-sdk/packages/flutter_tools/gradle/build.gradle.kts; then
          substituteInPlace flutter-sdk/packages/flutter_tools/gradle/build.gradle.kts \
            --replace-fail 'id("org.gradle.kotlin.kotlin-dsl") version "5.1.2"' 'id("org.gradle.kotlin.kotlin-dsl") version "6.4.2"'
        elif grep -Fq 'id("org.gradle.kotlin.kotlin-dsl") version "5.2.0"' flutter-sdk/packages/flutter_tools/gradle/build.gradle.kts; then
          substituteInPlace flutter-sdk/packages/flutter_tools/gradle/build.gradle.kts \
            --replace-fail 'id("org.gradle.kotlin.kotlin-dsl") version "5.2.0"' 'id("org.gradle.kotlin.kotlin-dsl") version "6.4.2"'
        fi

        cat > android/gradle-version-normalize.init.gradle << 'INIT_SCRIPT'
        allprojects {
          buildscript {
            configurations.matching { it.name == "classpath" }.all {
              resolutionStrategy.eachDependency { details ->
                if (details.requested.group == "com.android.tools.build" && details.requested.name == "gradle") {
                  details.useVersion("8.8.2")
                }
              }
            }
          }
        }
        INIT_SCRIPT

        cat > android/gradlew << 'GRADLEW_SCRIPT'
        #!/bin/sh
        exec ${gradle}/bin/gradle -I "$PWD/gradle-version-normalize.init.gradle" "$@"
        GRADLEW_SCRIPT
        chmod +x android/gradlew

        cat > .env <<APIKEYS
        API_KEY_WEATHERAPI=$(echo ZjFkZDE3MTFjNzgxNGE3NmFiNjQxODQ4MjUyMjA3Cg== | base64 -d)
        API_TOKEN=$(echo MWI1MDEyMGU4OWY4ZjExNjlkZGM1NWVmOGE5MzFmNzUxYjIwZDhmODRlMzc2OTlkODU4ZTdlY2M3YmI2MGNkMTA2MmY4ODViYmQ2Yzc3YjUK | base64 -d)
        API_KEY_OPENROUTER=$(echo c2stb3ItdjEtODQwY2Q2NmRiMThkNzU0NjQ0YjBiZTFhZDY5YzBiZDlmYjQxNmI2ZjY2OTk0NjBjZjczMDg3Y2Y2NmNiZWZhZQo= | base64 -d)
        APIKEYS
      '';

      preConfigure = ''
        export ANDROID_USER_HOME="$HOME/.android"
        mkdir -p "$ANDROID_USER_HOME"
        echo "sdk.dir=${androidSdk}/share/android-sdk" > android/local.properties
        echo "cmake.dir=${androidSdk}/share/android-sdk/cmake/3.31.6" >> android/local.properties
        echo "flutter.sdk=$PWD/flutter-sdk" >> android/local.properties
      '';

      preBuild = ''
        if grep -Fq 'id("org.gradle.kotlin.kotlin-dsl") version "5.1.2"' flutter-sdk/packages/flutter_tools/gradle/build.gradle.kts; then
          substituteInPlace flutter-sdk/packages/flutter_tools/gradle/build.gradle.kts \
            --replace-fail 'id("org.gradle.kotlin.kotlin-dsl") version "5.1.2"' 'id("org.gradle.kotlin.kotlin-dsl") version "6.4.2"'
        elif grep -Fq 'id("org.gradle.kotlin.kotlin-dsl") version "5.2.0"' flutter-sdk/packages/flutter_tools/gradle/build.gradle.kts; then
          substituteInPlace flutter-sdk/packages/flutter_tools/gradle/build.gradle.kts \
            --replace-fail 'id("org.gradle.kotlin.kotlin-dsl") version "5.2.0"' 'id("org.gradle.kotlin.kotlin-dsl") version "6.4.2"'
        fi
        printf '%s\n' \
          'storePassword=android' \
          'keyPassword=android' \
          'keyAlias=androiddebugkey' \
          'storeFile=debug.keystore' > android/key.properties

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
        GRADLE_OPTS="$GRADLE_OPTS -Dandroid.builder.sdkDownload=false"
        GRADLE_OPTS="$GRADLE_OPTS -Dorg.gradle.java.installations.auto-download=false"
        GRADLE_OPTS="$GRADLE_OPTS -Dorg.gradle.java.installations.paths=${jdk17_headless}"
        GRADLE_OPTS="$GRADLE_OPTS -Dandroid.aapt2FromMavenOverride=${androidSdk}/share/android-sdk/build-tools/36.1.0/aapt2"
        GRADLE_OPTS="$GRADLE_OPTS -Dorg.gradle.project.android.aapt2FromMavenOverride=${androidSdk}/share/android-sdk/build-tools/36.1.0/aapt2"
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
        gradle :app:assembleRelease
        runHook postBuild
      '';

      installPhase = ''
        runHook preInstall
        apk_path=""
        for candidate in \
          android/app/build/outputs/apk/release/app-release.apk \
          build/app/outputs/flutter-apk/app-release.apk; do
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
