{
  mk-apk-package,
  lib,
  buildDartApplication,
  runCommand,
  flutter344,
  jdk17_headless,
  python3,
  stdenv,
  writableTmpDirAsHomeHook,
  androidSdkBuilder,
  inputs,
  path,
}:
let
  flutterApkHelpers = ../_shared/flutter-apk-helpers.sh;
  mkFlutterSdkSourceBuilder = import ../_shared/mk-flutter-sdk-source-builder.nix;
  runBuildTool = ./run-build-tool.sh;
  # Binary Gradle from nixpkgs. Overlay Gradle is source-built and would
  # rebuild the whole bootstrap chain when nixpkgs-patched changes.
  gradle = (import inputs.nixpkgs { inherit (stdenv.hostPlatform) system; }).gradle_9;

  appPackage =
    let
      androidSdk = androidSdkBuilder (s: [
        s.cmdline-tools-latest
        s.platform-tools
        s.platforms-android-34
        s.platforms-android-35
        s.platforms-android-36
        s.build-tools-36-0-0
        s.ndk-28-2-13676358
        s.cmake-3-22-1
      ]);

      inherit gradle;
      androidSdkRoot = "${androidSdk}/share/android-sdk";
      aapt2 = "${androidSdkRoot}/build-tools/36.0.0/aapt2";
      ndkVersion = "28.2.13676358";
      pythonWithYaml = python3.withPackages (ps: [ ps.pyyaml ]);
      uplinkSrc = "${inputs.nurpkgs}/by-name/up/uplink";

      aarch64AndroidPkgs = import path {
        config.allowUnfree = true;
        localSystem = stdenv.buildPlatform.system;
        crossSystem = {
          config = "aarch64-unknown-linux-android";
          androidSdkVersion = "35";
          androidNdkVersion = "28";
          useAndroidPrebuilt = true;
          rust.rustcTarget = "aarch64-linux-android";
        };
      };

      libhub = aarch64AndroidPkgs.rustPlatform.buildRustPackage {
        pname = "uplink-hub";
        version = "0.1.0";
        src = uplinkSrc;
        cargoLock.lockFile = "${uplinkSrc}/Cargo.lock";
        buildAndTestSubdir = "native/hub";
        doCheck = false;
      };
    in
    buildDartApplication.override { dart = flutter344; } (finalAttrs: {
      pname = "uplink";
      version = "1.0.0+1";

      src = uplinkSrc;

      pubspecLock = lib.importJSON ./pubspec.lock.json;

      sdkSourceBuilders = {
        flutter = mkFlutterSdkSourceBuilder {
          inherit runCommand;
          flutter = flutter344;
        };
      };

      # $(nix build .#apk_uplink.mitmCache.updateScript --no-link --print-out-paths)
      mitmCache = gradle.fetchDeps {
        inherit (finalAttrs) pname;
        attrPath = "apk_uplink";
        pkg = finalAttrs.finalPackage;
        data = ./uplink_deps.json;
        silent = false;
        useBwrap = false;
      };

      gradleUpdateScript = ''
        runHook preBuild
        runHook preGradleUpdate
        flutter build apk --release --no-pub --target-platform android-arm64
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
        UPLINK_LIBHUB_SO = "${libhub}/lib/libhub.so";
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
        setup_writable_flutter_sdk ${flutter344}
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
          echo "flutter.versionName=1.0.0"
          echo "flutter.versionCode=1"
        } > android/local.properties
      '';

      preBuild = ''
        . ${flutterApkHelpers}

        mkdir -p .bin
        cp ./rustup-fake.sh .bin/rustup
        chmod +x .bin/rustup
        export PATH="$(pwd)/.bin:$PATH"

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
        export CARGO_TARGET_DIR="$PWD/target"

        ${pythonWithYaml}/bin/python3 ${../_shared/generate-flutter-plugins.py}
        rm -f android/app/src/main/java/io/flutter/plugins/GeneratedPluginRegistrant.java

        mkdir -p .dart-patched
        declare -A patched_pkg_dirs
        while IFS= read -r plugin_dir; do
          [ -n "$plugin_dir" ] || continue
          ensure_writable_dart_package "$plugin_dir" >/dev/null
        done < <(${python3}/bin/python3 - <<'PY'
        import json

        with open(".flutter-plugins-dependencies") as f:
            data = json.load(f)
        for plugin in data.get("plugins", {}).get("android", []):
            path = plugin.get("path", "")
            if path:
                print(path)
        PY
        )

        while IFS= read -r plugin_gradle; do
          [ -n "$plugin_gradle" ] || continue
          case "$plugin_gradle" in
            *example*) continue ;;
          esac
          if grep -qx 'kotlin {' "$plugin_gradle"; then
            substituteInPlace "$plugin_gradle" \
              --replace-fail 'id("com.android.library")' $'id("com.android.library")\n    id("org.jetbrains.kotlin.android")'
          fi
        done < <(find .dart-patched -path '*/android/build.gradle.kts' -print)

        RINF_PATH=$(${python3}/bin/python3 - <<'PY'
        import json
        from urllib.parse import unquote, urlparse

        with open(".dart_tool/package_config.json") as f:
            data = json.load(f)
        for package in data.get("packages", []):
            if package.get("name") != "rinf":
                continue
            root_uri = package.get("rootUri", "")
            parsed = urlparse(root_uri)
            print(unquote(parsed.path))
            break
        PY
        )
        if [ -z "$RINF_PATH" ]; then
          echo "rinf package path not found" >&2
          exit 1
        fi
        rinf_dir="$(ensure_writable_dart_package "$RINF_PATH")"
        cp ${runBuildTool} "$rinf_dir/cargokit/run_build_tool.sh"
        chmod +x "$rinf_dir/cargokit/run_build_tool.sh"
        cp ${./cargokit-plugin.gradle} "$rinf_dir/cargokit/gradle/plugin.gradle"
      '';

      buildPhase = ''
        runHook preBuild
        flutter build apk --release --no-pub --target-platform android-arm64
        runHook postBuild
      '';

      installPhase = ''
        runHook preInstall
        install -Dm644 build/app/outputs/flutter-apk/app-release.apk \
          "$out/uplink.apk"
        runHook postInstall
      '';

      meta = with lib; {
        description = "Uplink pastebin GUI Android client built from source";
        homepage = "https://github.com/mio-19/nurpkgs/tree/main/by-name/up/uplink";
        license = licenses.mit;
        platforms = platforms.unix;
      };
    });
in
mk-apk-package {
  inherit appPackage;
  mainApk = "uplink.apk";
  signScriptName = "sign-uplink";
  fdroid = {
    appId = "com.example.uplink";
    metadataYml = ''
      Categories:
        - Internet
      License: MIT
      SourceCode: https://github.com/mio-19/nurpkgs
      IssueTracker: https://github.com/mio-19/nurpkgs/issues
      AutoName: Uplink
      Summary: Cross-platform pastebin GUI
      Description: |-
        Uplink is a Flutter client for uploading text and files to a pastebin
        backend, with a Rust native hub.
    '';
  };
}
