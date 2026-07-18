{
  mk-apk-package,
  lib,
  buildDartApplication,
  runCommand,
  fetchFromGitHub,
  flutter344,
  git,
  jdk17_headless,
  curl,
  python3,
  writableTmpDirAsHomeHook,
  androidSdkBuilder,
  applyPatches,
  gradle_8_14_3,
  zip,
  fetchurl,
}:
let
  appPackage =
    let
      androidSdk = androidSdkBuilder (s: [
        s.cmdline-tools-latest
        s.platform-tools
        s.platforms-android-33
        s.platforms-android-34
        s.platforms-android-35
        s.platforms-android-36
        s.build-tools-35-0-0
        s.build-tools-36-1-0
        s.ndk-27-0-12077973
        s.ndk-28-2-13676358
        s.ndk-29-0-14206865
        s.cmake-3-31-6
      ]);

      gradle = gradle_8_14_3;

      gradleZip =
        runCommand "gradle-${gradle.version}-wrapper.zip"
          {
            nativeBuildInputs = [ zip ];
          }
          ''
            cd ${gradle}/libexec/gradle
            zip -qr $out .
          '';

      pythonWithYaml = python3.withPackages (ps: [ ps.pyyaml ]);
      androidSdkRoot = "${androidSdk}/share/android-sdk";
      aapt2Path = "${androidSdkRoot}/build-tools/36.1.0/aapt2";
      gradleCommonOpts = [
        "-Dorg.gradle.java.installations.auto-download=false"
        "-Dorg.gradle.java.installations.paths=${jdk17_headless}"
        "-Dandroid.aapt2FromMavenOverride=${aapt2Path}"
        "-Dorg.gradle.project.android.aapt2FromMavenOverride=${aapt2Path}"
      ];
    in
    buildDartApplication.override { dart = flutter344; } (finalAttrs: {
      pname = "immich";
      version = "3.0.3";

      src = applyPatches {
        src = fetchFromGitHub {
          owner = "immich-app";
          repo = "immich";
          tag = "v${finalAttrs.version}";
          fetchSubmodules = true;
          hash = "sha256-pzO5c6fP3G5x+cN2QS6LyjZlNXujFWxz8W9RqX8g5Es=";
        };
        patches = [
          /*
            # TODO:
            (fetchpatch {
              name = "feat: show notification and battery optimization warning";
              url = "https://github.com/immich-app/immich/pull/26610.diff";
              hash = "sha256-TBXPSuikeq0S2o/+sl6F+twfMxJBkCuiwpdK88mn6L8=";
            })
          */
          /*
            # TODO:
            (fetchpatch {
              name = "feat(mobile): Android. Immich as a gallery / image viewer app";
              url = "https://github.com/immich-app/immich/pull/26109.diff";
              hash = "sha256-+RyJYGO4YYs/xDHIfpi1dHXW11avny7gLZ2Ew15gJY0=";
            })
          */
          /*
            # TODO:
            (fetchpatch {
              name = "feat(mobile): increased tap area on video player overlay";
              url = "https://github.com/immich-app/immich/pull/27269.diff";
              hash = "sha256-/Sc+Z6K23QgKjVUemI4TkD0MqXdfzeTFl4hZHuSW7Ng=";
            })
          */
        ];
      };

      sourceRoot = "${finalAttrs.src.name}/mobile";
      packageRoot = "mobile";
      patches = [
        ./disable-release-lint.patch
      ];

      pubspecLock = lib.importJSON ./pubspec.lock.json;
      gitHashes = lib.importJSON ./git-hashes.json;

      sdkSourceBuilders = {
        flutter =
          name:
          runCommand "flutter-sdk-${name}" { passthru.packageRoot = "."; } ''
            for path in \
              '${flutter344}/packages/${name}' \
              '${flutter344}/bin/cache/pkg/${name}'; do
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

      gradleUpdateTask = ":app:assembleRelease extractReleaseAnnotations";

      gradleUpdateScript = ''
        runHook preBuild
        runHook preGradleUpdate
        flutter build apk --release --no-pub --dart-define=cronetHttpNoPlay=true
        runHook postGradleUpdate
      '';

      dontDartBuild = true;
      dontDartInstall = true;

      nativeBuildInputs = [
        curl
        gradle
        git
        jdk17_headless
        python3
        writableTmpDirAsHomeHook
      ];

      env = {
        JAVA_HOME = jdk17_headless;
        ANDROID_HOME = androidSdkRoot;
        ANDROID_SDK_ROOT = androidSdkRoot;
        ANDROID_AAPT2_FROM_MAVEN_OVERRIDE = aapt2Path;
      };

      gradleFlags = [
        "-xlintVitalRelease"
        "--project-dir"
        "android"
      ]
      ++ gradleCommonOpts;

      postPatch = ''
        cp -LR ${flutter344} flutter-sdk
        chmod -R u+w flutter-sdk
        touch flutter-sdk/bin/cache/engine.realm # https://github.com/NixOS/nixpkgs/pull/500309#issuecomment-4192628176

        substituteInPlace android/app/build.gradle \
          --replace-fail "//f configurations.all {" "configurations.all {" \
          --replace-fail "//f     exclude group: 'com.google.android.gms'" "    exclude group: 'com.google.android.gms'" \
          --replace-fail "//f }" "}" \
          --replace-fail "signingConfig hasKeystore ? signingConfigs.release : signingConfigs.debug" "signingConfig signingConfigs.debug"

        substituteInPlace android/gradle.properties \
          --replace-fail "org.gradle.jvmargs=-Xmx4096M" "org.gradle.jvmargs=-Xmx8192M"

        sed -i '1i subprojects { afterEvaluate { project -> if (project.hasProperty("android")) { project.android.buildToolsVersion = "36.1.0" } } }' android/build.gradle

        ${lib.concatStringsSep "\n" (
          lib.mapAttrsToList
            (arch: src: ''
              mkdir -p android/app/src/main/jniLibs/${arch}
              cp ${src} android/app/src/main/jniLibs/${arch}/libsqlite3.so
            '')
            {
              "armeabi-v7a" = fetchurl {
                url = "https://github.com/simolus3/sqlite3.dart/releases/download/sqlite3-3.3.2/libsqlite3.arm.android.so";
                sha256 = "1jbmma7vvnn2kigvvzlfp55wbi08rw03cwl6w93xcn6kxja9aw91";
              };
              "arm64-v8a" = fetchurl {
                url = "https://github.com/simolus3/sqlite3.dart/releases/download/sqlite3-3.3.2/libsqlite3.arm64.android.so";
                sha256 = "1n5sca3ps0avxfxjdcjyxrxpjrm7kixbvd8dw8j367g38mj1f79z";
              };
              "x86_64" = fetchurl {
                url = "https://github.com/simolus3/sqlite3.dart/releases/download/sqlite3-3.3.2/libsqlite3.x64.android.so";
                sha256 = "18d6idsw5plcp951nadh86klfv814mmpy6iv8v0pjdxz5kwck9h7";
              };
              "x86" = fetchurl {
                url = "https://github.com/simolus3/sqlite3.dart/releases/download/sqlite3-3.3.2/libsqlite3.ia32.android.so";
                sha256 = "1sb0rmbxvs9x1fz458i1yxk30hy2c990dkxac4fdbv9430pzvspf";
              };
            }
        )}

        printf '%s\n' '#!/bin/sh' 'exec ${gradle}/bin/gradle "$@"' > android/gradlew
        chmod +x android/gradlew

        {
          echo 'distributionBase=GRADLE_USER_HOME'
          echo 'distributionPath=wrapper/dists'
          echo "distributionUrl=file\://${gradleZip}"
          echo 'networkTimeout=10000'
          echo 'validateDistributionUrl=false'
          echo 'zipStoreBase=GRADLE_USER_HOME'
          echo 'zipStorePath=wrapper/dists'
        } > android/gradle/wrapper/gradle-wrapper.properties

      '';

      preConfigure = ''
        export ANDROID_USER_HOME="$HOME/.android"
        mkdir -p "$ANDROID_USER_HOME"
        export PUB_CACHE="$PWD/.pub-cache"

        echo "sdk.dir=${androidSdkRoot}" > android/local.properties
        echo "cmake.dir=${androidSdkRoot}/cmake/3.31.6" >> android/local.properties
        echo "flutter.sdk=$PWD/flutter-sdk" >> android/local.properties
        echo "flutter.versionName=3.0.1" >> android/local.properties
        echo "flutter.versionCode=3054" >> android/local.properties
      '';

      preBuild = ''
        GRADLE_OPTS="''${GRADLE_OPTS:-}"
        for gradle_opt in ${lib.escapeShellArgs gradleCommonOpts}; do
          GRADLE_OPTS="$GRADLE_OPTS $gradle_opt"
        done
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

        if [[ -n "''${MITM_CACHE_HOST:-}" && -n "''${MITM_CACHE_PORT:-}" && -n "''${MITM_CACHE_CA:-}" ]]; then
          for artifact_url in \
            https://dl.google.com/dl/android/maven2/androidx/appcompat/appcompat/1.2.0/appcompat-1.2.0.aar \
            https://dl.google.com/dl/android/maven2/androidx/appcompat/appcompat-resources/1.2.0/appcompat-resources-1.2.0.aar \
            https://dl.google.com/dl/android/maven2/androidx/transition/transition/1.4.1/transition-1.4.1.aar \
            https://dl.google.com/dl/android/maven2/androidx/room/room-ktx/2.5.0/room-ktx-2.5.0.aar \
            https://dl.google.com/dl/android/maven2/androidx/room/room-runtime/2.5.0/room-runtime-2.5.0.aar \
            https://dl.google.com/dl/android/maven2/androidx/sqlite/sqlite-framework/2.3.0/sqlite-framework-2.3.0.aar \
            https://dl.google.com/dl/android/maven2/androidx/sqlite/sqlite/2.3.0/sqlite-2.3.0.aar \
            https://dl.google.com/dl/android/maven2/androidx/profileinstaller/profileinstaller/1.3.1/profileinstaller-1.3.1.aar \
            https://dl.google.com/dl/android/maven2/androidx/compose/remote/remote-creation-android/1.0.0-alpha14/remote-creation-android-1.0.0-alpha14.aar \
            https://dl.google.com/dl/android/maven2/androidx/compose/remote/remote-creation/1.0.0-alpha14/remote-creation-1.0.0-alpha14.aar
          do
            ${curl}/bin/curl --silent --show-error --fail --location \
              --proxy "http://$MITM_CACHE_HOST:$MITM_CACHE_PORT" \
              --cacert "$MITM_CACHE_CA" \
              --output /dev/null \
              "$artifact_url"
          done
        fi

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

        replace_flutter_plugin_root() {
          local original_dir="$1"
          local patched_dir="$2"

          if [ -f .flutter-plugins-dependencies ] && grep -Fq "$original_dir" .flutter-plugins-dependencies; then
            substituteInPlace .flutter-plugins-dependencies \
              --replace-fail "$original_dir" "$patched_dir"
          fi

          if [ -f .flutter-plugins ] && grep -Fq "$original_dir" .flutter-plugins; then
            substituteInPlace .flutter-plugins \
              --replace-fail "$original_dir" "$patched_dir"
          fi
        }

        remap_dart_package_root() {
          local original_dir="$1"
          local patched_dir="$2"

          replace_dart_package_root "$original_dir" "$patched_dir"
          replace_flutter_plugin_root "$original_dir" "$patched_dir"
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
          patch \
            -d "$patched_geolocator_android_dir/android/src/main/java/com/baseflow/geolocator/location" \
            -p1 < ${./geolocator-force-locationmanager.patch}

          remap_dart_package_root "$GEOLOCATOR_ANDROID_DIR" "$patched_geolocator_android_dir"
        fi

        flutter_engine_version="$(cat flutter-sdk/bin/internal/engine.version)"
        if [ -n "$NATIVE_VIDEO_PLAYER_DIR" ] || [ -n "$HOME_WIDGET_DIR" ]; then
          if [ -n "$NATIVE_VIDEO_PLAYER_DIR" ]; then
            patched_native_video_player_dir="$(clone_dart_package "$NATIVE_VIDEO_PLAYER_DIR" native_video_player)"
            substituteInPlace "$patched_native_video_player_dir/android/build.gradle" \
              --replace-warn '     implementation("androidx.media3:media3-ui:1.9.2")' \
                "     implementation(\"androidx.media3:media3-ui:1.9.2\")
         implementation \"androidx.annotation:annotation:1.8.0\"
         compileOnly \"io.flutter:flutter_embedding_release:1.0.0-$flutter_engine_version\""
            remap_dart_package_root "$NATIVE_VIDEO_PLAYER_DIR" "$patched_native_video_player_dir"
            NATIVE_VIDEO_PLAYER_DIR="$patched_native_video_player_dir"
          fi

          if [ -n "$HOME_WIDGET_DIR" ]; then
            patched_home_widget_dir="$(clone_dart_package "$HOME_WIDGET_DIR" home_widget)"
            substituteInPlace "$patched_home_widget_dir/android/build.gradle" \
              --replace-warn '    implementation "org.jetbrains.kotlinx:kotlinx-coroutines-android:1.+"' \
                "    implementation \"org.jetbrains.kotlinx:kotlinx-coroutines-android:1.+\"
        compileOnly \"io.flutter:flutter_embedding_release:1.0.0-$flutter_engine_version\""
            remap_dart_package_root "$HOME_WIDGET_DIR" "$patched_home_widget_dir"
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
              --replace-fail '  implementation libs.kotlinx.serialization.json' \
                $'  implementation libs.kotlinx.serialization.json\n  implementation project(\x27:native_video_player\x27)\n  implementation project(\x27:home_widget\x27)'
          fi
        fi

        declare -A patched_pkg_dirs
        while IFS= read -r pkg_dir; do
          [ -d "$pkg_dir/android" ] || continue
          [[ "$pkg_dir" == /nix/store/* ]] || continue
          if [ -z "''${patched_pkg_dirs[$pkg_dir]:-}" ]; then
            patched_pkg_dirs[$pkg_dir]="$(clone_dart_package "$pkg_dir" "$(basename "$pkg_dir")")"
          fi
          remap_dart_package_root "$pkg_dir" "''${patched_pkg_dirs[$pkg_dir]}"
        done < <(${python3}/bin/python3 - <<'PY'
        import json
        import urllib.parse

        with open(".dart_tool/package_config.json") as f:
            data = json.load(f)

        seen = set()
        for pkg in data["packages"]:
            uri = pkg.get("rootUri", "")
            if not uri.startswith("file://"):
                continue
            path = urllib.parse.urlparse(uri).path.removesuffix("/.")
            if path and path not in seen:
                seen.add(path)
                print(path)
        PY
        )

        ${pythonWithYaml}/bin/python3 ${../_shared/generate-flutter-plugins.py}
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
  fdroid = {
    appId = "app.alextran.immich";
    metadataYml = ''
      Categories:
        - Cloud Storage & File Sync
        - Multimedia
        - System
      License: AGPL-3.0-only
      SourceCode: https://github.com/immich-app/immich
      IssueTracker: https://github.com/immich-app/immich/issues
      Translation: https://hosted.weblate.org/projects/immich/
      Changelog: https://github.com/immich-app/immich/releases
      AutoName: Immich
      Summary: Photo and video backup app
      Description: |-
        Immich is a self-hosted photo and video backup application.

        This package builds the Android mobile app from source.
    '';
  };
}
