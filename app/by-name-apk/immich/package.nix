{
  mk-apk-package,
  lib,
  buildDartApplication,
  runCommand,
  fetchFromGitHub,
  flutter335,
  git,
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
        s.platforms-android-36
        s.build-tools-35-0-0
        s.build-tools-36-0-0
        s.ndk-28-2-13676358
        s.cmake-3-22-1
      ]);

      gradle =
        (gradle-packages.mkGradle {
          version = "8.13";
          hash = "sha256-IPGxF2I3JUpvwgTYQ0GW+hGkz7OHVnUZxhVW6HEK7Xg=";
          defaultJava = jdk17_headless;
        }).wrapped;
    in
    buildDartApplication.override { dart = flutter335; } (finalAttrs: {
      pname = "immich";
      version = "2.6.3+3041";

      src = fetchFromGitHub {
        owner = "immich-app";
        repo = "immich";
        tag = "v2.6.3";
        fetchSubmodules = true;
        hash = "sha256-2vkHeTUPezEf6Qz4bVmln7unTIVuGdzXPTjr6vnW0NE=";
      };

      sourceRoot = "source/mobile";
      packageRoot = "mobile";
      patches = [ ./disable-release-lint.patch ];

      pubspecLock = lib.importJSON ./pubspec.lock.json;
      gitHashes = lib.importJSON ./git-hashes.json;

      sdkSourceBuilders = {
        flutter =
          name:
          runCommand "flutter-sdk-${name}" { passthru.packageRoot = "."; } ''
            for path in \
              '${flutter335}/packages/${name}' \
              '${flutter335}/bin/cache/pkg/${name}'; do
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
        data = ./immich_deps.json;
        silent = false;
        useBwrap = false;
      };

      gradleUpdateTask = ":assembleRelease :app:assembleRelease :home_widget:assembleRelease home_widget:extractReleaseAnnotations :home_widget:mapReleaseSourceSetPaths :home_widget:mapReleaseSourceSetPaths";

      dontDartBuild = true;
      dontDartInstall = true;

      nativeBuildInputs = [
        gradle
        git
        jdk17_headless
        python3
        writableTmpDirAsHomeHook
      ];

      env = {
        JAVA_HOME = jdk17_headless;
        ANDROID_HOME = "${androidSdk}/share/android-sdk";
        ANDROID_SDK_ROOT = "${androidSdk}/share/android-sdk";
        ANDROID_NDK_HOME = "${androidSdk}/share/android-sdk/ndk/28.2.13676358";
        ANDROID_NDK_ROOT = "${androidSdk}/share/android-sdk/ndk/28.2.13676358";
        ANDROID_AAPT2_FROM_MAVEN_OVERRIDE = "${androidSdk}/share/android-sdk/build-tools/35.0.0/aapt2";
      };

      gradleFlags = [
        "-xlintVitalRelease"
        "--project-dir"
        "android"
        "-Dorg.gradle.java.installations.auto-download=false"
        "-Dorg.gradle.java.installations.paths=${jdk17_headless}"
        "-Dandroid.aapt2FromMavenOverride=${androidSdk}/share/android-sdk/build-tools/35.0.0/aapt2"
        "-Dorg.gradle.project.android.aapt2FromMavenOverride=${androidSdk}/share/android-sdk/build-tools/35.0.0/aapt2"
      ];

      postPatch = ''
        cp -LR ${flutter335} flutter-sdk
        chmod -R u+w flutter-sdk

        cat > android/gradlew << 'GRADLEW_SCRIPT'
        #!/bin/sh
        exec ${gradle}/bin/gradle "$@"
        GRADLEW_SCRIPT
        chmod +x android/gradlew

        pluginResolutionBlock=$'pluginManagement {\n    resolutionStrategy {\n        eachPlugin {\n            if (requested.id.id == "com.android.application") {\n                def agpVersion = requested.version ?: "8.10.1"\n                useModule("com.android.tools.build:gradle:''${agpVersion}")\n            }\n        }\n    }\n'
        substituteInPlace android/settings.gradle \
          --replace-fail "pluginManagement {" "$pluginResolutionBlock"

        substituteInPlace android/app/build.gradle \
          --replace-fail "//f configurations.all {" "configurations.all {" \
          --replace-fail "//f     exclude group: 'com.google.android.gms'" "    exclude group: 'com.google.android.gms'" \
          --replace-fail "//f }" "}" \
          --replace-fail "      signingConfig signingConfigs.release" ""

        substituteInPlace android/settings.gradle \
          --replace-fail "id \"com.android.application\" version '8.11.2' apply false" \
            "id \"com.android.application\" version '8.10.1' apply false"

        substituteInPlace android/gradle.properties \
          --replace-fail "org.gradle.jvmargs=-Xmx4096M" "org.gradle.jvmargs=-Xmx8192M"
      '';

      preConfigure = ''
        export ANDROID_USER_HOME="$HOME/.android"
        mkdir -p "$ANDROID_USER_HOME"
        export PUB_CACHE="$PWD/.pub-cache"

        echo "sdk.dir=${androidSdk}/share/android-sdk" > android/local.properties
        echo "cmake.dir=${androidSdk}/share/android-sdk/cmake/3.22.1" >> android/local.properties
        echo "flutter.sdk=$PWD/flutter-sdk" >> android/local.properties
        echo "flutter.versionName=2.6.1" >> android/local.properties
        echo "flutter.versionCode=3039" >> android/local.properties
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

        packageRun easy_localization -e generate -S ../i18n
        dart --packages=.dart_tool/package_config.json bin/generate_keys.dart
        dart format lib/generated/codegen_loader.g.dart lib/generated/translations.g.dart

        mkdir -p .dart-patched

        clone_dart_package() {
          local source_dir="$1"
          local patched_name="$2"
          local patched_dir="$PWD/.dart-patched/$patched_name"

          cp -LR "$source_dir" "$patched_dir"
          chmod -R u+w "$patched_dir"
          printf '%s\n' "$patched_dir"
        }

        replace_dart_package_root() {
          local original_dir="$1"
          local patched_dir="$2"

          substituteInPlace .dart_tool/package_config.json \
            --replace-fail "$original_dir" "$patched_dir"
        }

        ${python3}/bin/python3 - <<'PY' > dart_package_dirs.sh
        import json
        import shlex
        import urllib.parse

        with open(".dart_tool/package_config.json") as f:
            data = json.load(f)

        wanted = {
            "geolocator_android": "GEOLOCATOR_ANDROID_DIR",
            "native_video_player": "NATIVE_VIDEO_PLAYER_DIR",
            "home_widget": "HOME_WIDGET_DIR",
        }

        found = {env_name: "" for env_name in wanted.values()}
        for pkg in data["packages"]:
            env_name = wanted.get(pkg["name"])
            if env_name:
                found[env_name] = urllib.parse.urlparse(pkg["rootUri"]).path.removesuffix("/.")

        for env_name, path in found.items():
            print(f"export {env_name}={shlex.quote(path)}")
        PY
        . ./dart_package_dirs.sh

        if [ -n "$GEOLOCATOR_ANDROID_DIR" ]; then
          patched_geolocator_android_dir="$(clone_dart_package "$GEOLOCATOR_ANDROID_DIR" geolocator_android)"

          substituteInPlace "$patched_geolocator_android_dir/android/build.gradle" \
            --replace-fail "    implementation 'com.google.android.gms:play-services-location:21.2.0'" ""

          rm "$patched_geolocator_android_dir/android/src/main/java/com/baseflow/geolocator/location/FusedLocationClient.java"
          install -m644 ${./GeolocationManager.java} \
            "$patched_geolocator_android_dir/android/src/main/java/com/baseflow/geolocator/location/GeolocationManager.java"

          replace_dart_package_root "$GEOLOCATOR_ANDROID_DIR" "$patched_geolocator_android_dir"
        fi

        flutter_engine_version="$(cat flutter-sdk/bin/internal/engine.version)"
        if [ -n "$NATIVE_VIDEO_PLAYER_DIR" ] || [ -n "$HOME_WIDGET_DIR" ]; then
          if [ -n "$NATIVE_VIDEO_PLAYER_DIR" ]; then
            patched_native_video_player_dir="$(clone_dart_package "$NATIVE_VIDEO_PLAYER_DIR" native_video_player)"
            substituteInPlace "$patched_native_video_player_dir/android/build.gradle" \
              --replace-fail "    ext.kotlin_version = '2.2.20'" "    ext.kotlin_version = '2.0.20'" \
              --replace-fail '        classpath("com.android.tools.build:gradle:8.13.2")' \
                '        classpath("com.android.tools.build:gradle:8.1.2")' \
              --replace-fail '     implementation("androidx.media3:media3-ui:1.9.2")' \
                "     implementation(\"androidx.media3:media3-ui:1.9.2\")
         implementation \"androidx.annotation:annotation:1.8.0\"
         compileOnly \"io.flutter:flutter_embedding_release:1.0.0-$flutter_engine_version\""
            replace_dart_package_root "$NATIVE_VIDEO_PLAYER_DIR" "$patched_native_video_player_dir"
            NATIVE_VIDEO_PLAYER_DIR="$patched_native_video_player_dir"
          fi

          if [ -n "$HOME_WIDGET_DIR" ]; then
            patched_home_widget_dir="$(clone_dart_package "$HOME_WIDGET_DIR" home_widget)"
            substituteInPlace "$patched_home_widget_dir/android/build.gradle" \
              --replace-fail '    implementation "androidx.glance:glance-appwidget:1.+"' \
                '    implementation "androidx.glance:glance-appwidget:1.2.0-rc01"' \
              --replace-fail '    implementation "androidx.work:work-runtime-ktx:2.+"' \
                '    implementation "androidx.work:work-runtime-ktx:2.11.2"' \
              --replace-fail '    implementation "org.jetbrains.kotlinx:kotlinx-coroutines-android:1.+"' \
                "    implementation \"org.jetbrains.kotlinx:kotlinx-coroutines-android:1.+\"
        compileOnly \"io.flutter:flutter_embedding_release:1.0.0-$flutter_engine_version\""
            replace_dart_package_root "$HOME_WIDGET_DIR" "$patched_home_widget_dir"
            HOME_WIDGET_DIR="$patched_home_widget_dir"
          fi

          : > android/local-plugin-settings.gradle
          if [ -n "$NATIVE_VIDEO_PLAYER_DIR" ]; then
            printf '%s\n' \
              'include(":native_video_player")' \
              "project(\":native_video_player\").projectDir = new File(\"$NATIVE_VIDEO_PLAYER_DIR/android\")" \
              >> android/local-plugin-settings.gradle
          fi
          if [ -n "$HOME_WIDGET_DIR" ]; then
            printf '%s\n' \
              'include(":home_widget")' \
              "project(\":home_widget\").projectDir = new File(\"$HOME_WIDGET_DIR/android\")" \
              >> android/local-plugin-settings.gradle
          fi

          if ! grep -Fq 'apply from: "local-plugin-settings.gradle"' android/settings.gradle; then
            printf '\napply from: "local-plugin-settings.gradle"\n' >> android/settings.gradle
          fi

          if ! grep -Fq "implementation project(':native_video_player')" android/app/build.gradle; then
            substituteInPlace android/app/build.gradle \
              --replace-fail 'implementation "org.jetbrains.kotlinx:kotlinx-serialization-json:$serialization_version"' \
                $'implementation "org.jetbrains.kotlinx:kotlinx-serialization-json:$serialization_version"\n  implementation project(\x27:native_video_player\x27)\n  implementation project(\x27:home_widget\x27)'
          fi
        fi
      '';

      buildPhase = ''
        runHook preBuild
        flutter build apk --release --no-pub --dart-define=cronetHttpNoPlay=true
        runHook postBuild
      '';

      installPhase = ''
        runHook preInstall

        apk_path="$(echo build/app/outputs/flutter-apk/*.apk | awk '{print $1}')"
        install -Dm644 "$apk_path" "$out/immich.apk"

        runHook postInstall
      '';

      meta = with lib; {
        description = "Immich mobile app built from source";
        homepage = "https://github.com/immich-app/immich";
        license = licenses.agpl3Only;
        platforms = platforms.unix;
      };
    });
in
mk-apk-package {
  inherit appPackage;
  mainApk = "immich.apk";
  signScriptName = "sign-immich";
}
