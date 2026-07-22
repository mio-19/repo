{
  mk-apk-package,
  lib,
  buildDartApplication,
  runCommand,
  fetchFromGitHub,
  fetchurl,
  flutter338,
  jdk17_headless,
  python3,
  gradle_8_12,
  writableTmpDirAsHomeHook,
  androidSdkBuilder,
}:
let
  flutterApkHelpers = ../_shared/flutter-apk-helpers.sh;
  mkFlutterSdkSourceBuilder = import ../_shared/mk-flutter-sdk-source-builder.nix;

  appPackage =
    let
      # Upstream llamadart downloads these at build time; vendor the release
      # tarballs instead so the sandboxed build stays offline.
      llamadartNativeAndroidArm64 = fetchurl {
        url = "https://github.com/leehack/llamadart-native/releases/download/b9587/llamadart-native-android-arm64-b9587.tar.gz";
        hash = "sha256-XSqFp2MIiD+TQf2bCtjjwL3a/T9Ym+Mz0v8wZecg6qc=";
      };

      litertLMNativeAndroidArm64 = fetchurl {
        url = "https://github.com/leehack/litert-lm-native/releases/download/v0.13.1-native.1/litert-lm-native-runtime-android-arm64-v0.13.1-native.1.tar.gz";
        hash = "sha256-JYaj9FOnciNmIQoA/TZUAehBENIU5yMIM0P7YKwRGnQ=";
      };

      androidSdk = androidSdkBuilder (s: [
        s.cmdline-tools-latest
        s.platform-tools
        s.platforms-android-35
        s.platforms-android-36
        # AGP may resolve aapt2 from build-tools 35.0.0 even with compileSdk 36.
        s.build-tools-35-0-0
        s.build-tools-36-0-0
        # App uses 29 (upstream); jni/jni_flutter plugins still declare 28.2.
        # Do not set ndk.dir in local.properties — let AGP pick per-module.
        s.ndk-28-2-13676358
        s.ndk-29-0-14206865
        s.cmake-3-31-6
      ]);

      gradle = gradle_8_12;
      androidSdkRoot = "${androidSdk}/share/android-sdk";
      aapt2 = "${androidSdkRoot}/build-tools/35.0.0/aapt2";

      pythonWithYaml = python3.withPackages (ps: [ ps.pyyaml ]);
    in
    buildDartApplication.override { dart = flutter338; } (finalAttrs: {
      pname = "meshcore-open";
      version = "9.5.0+13";

      src = fetchFromGitHub {
        owner = "zjs81";
        repo = "meshcore-open";
        rev = "PRE-BETA-9.5";
        hash = "sha256-H2kraJIk9H4FHFQFXU1FLEdjwZpaN6C8lUq42/yE72I=";
      };

      pubspecLock = lib.importJSON ./pubspec.lock.json;

      gitHashes = {
        flserial = "sha256-+v8++zKQkhI4KKyaiE14RxC/kCE96EMFVW4h7914cC0=";
      };

      sdkSourceBuilders = {
        flutter = mkFlutterSdkSourceBuilder {
          inherit runCommand;
          flutter = flutter338;
        };
      };

      # $(nix build .#apk_meshcore-open.mitmCache.updateScript --no-link --print-out-paths)
      mitmCache = gradle.fetchDeps {
        inherit (finalAttrs) pname;
        attrPath = "apk_meshcore-open";
        pkg = finalAttrs.finalPackage;
        data = ./meshcore-open_deps.json;
        silent = false;
        useBwrap = false;
      };

      gradleUpdateTask = "--init-script ${./androidx-resolution.init.gradle} :app:assembleRelease :flserial:extractReleaseAnnotations";

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
        ANDROID_HOME = androidSdkRoot;
        ANDROID_SDK_ROOT = androidSdkRoot;
        ANDROID_AAPT2_FROM_MAVEN_OVERRIDE = aapt2;
      };

      sdkSetupScript = ''
        flutter config --no-analytics >/dev/null 2>&1 || true
      '';

      gradleFlags = [
        "-xlintVitalRelease"
        "--project-dir"
        "android"
        "-Dorg.gradle.java.installations.auto-download=false"
        "-Dorg.gradle.java.installations.paths=${jdk17_headless}"
        "-Dandroid.aapt2FromMavenOverride=${aapt2}"
        "-Dorg.gradle.project.android.aapt2FromMavenOverride=${aapt2}"
      ];

      postPatch = ''
        . ${flutterApkHelpers}

        # Upstream still uses the old ReorderableListView callback name.
        substituteInPlace lib/screens/channels_screen.dart \
          --replace-fail 'onReorderItem:' 'onReorder:'
        substituteInPlace lib/widgets/path_editor_sheet.dart \
          --replace-fail 'onReorderItem:' 'onReorder:'

        setup_writable_flutter_sdk ${flutter338}
        setup_pinned_gradlew ${gradle}/bin/gradle "-I ${./androidx-resolution.init.gradle} "
      '';

      preConfigure = ''
        export ANDROID_USER_HOME="$HOME/.android"
        mkdir -p "$ANDROID_USER_HOME"
        {
          echo "sdk.dir=${androidSdkRoot}"
          echo "cmake.dir=${androidSdkRoot}/cmake/3.31.6"
          echo "flutter.sdk=$PWD/flutter-sdk"
        } > android/local.properties
      '';

      preBuild = ''
        . ${flutterApkHelpers}

        GRADLE_OPTS="''${GRADLE_OPTS:-}"
        GRADLE_OPTS="$GRADLE_OPTS -Dorg.gradle.java.installations.auto-download=false"
        GRADLE_OPTS="$GRADLE_OPTS -Dorg.gradle.java.installations.paths=${jdk17_headless}"
        GRADLE_OPTS="$GRADLE_OPTS -Dandroid.aapt2FromMavenOverride=${aapt2}"
        GRADLE_OPTS="$GRADLE_OPTS -Dorg.gradle.project.android.aapt2FromMavenOverride=${aapt2}"
        append_mitm_gradle_opts
        export FLUTTER_ROOT="$PWD/flutter-sdk"
        export LLAMADART_ALLOW_LEGACY_LOCAL_BUNDLES=1

        mkdir -p .dart-patched
        declare -A patched_pkg_dirs

        ${pythonWithYaml}/bin/python3 ${../_shared/generate-flutter-plugins.py}

        # Flutter plugins live in the Nix store; CMake/AGP write under plugin
        # android/ trees (e.g. flserial .cxx/), so clone them to a writable dir.
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

        # Vendor llamadart / litert native bundles so hook/build.dart does not
        # hit the network during the sandboxed Flutter build.
        while IFS= read -r package_dir; do
          [ -n "$package_dir" ] || continue
          work_package_dir="$(ensure_writable_dart_package "$package_dir")"
          mkdir -p "$work_package_dir/third_party/bin/android/arm64"
          tar -xzf ${llamadartNativeAndroidArm64} -C "$work_package_dir/third_party/bin/android/arm64"
          substituteInPlace "$work_package_dir/hook/build.dart" \
            --replace-fail \
              "  final request = http.Request('GET', Uri.parse(url));" \
              $'  await File(\'${llamadartNativeAndroidArm64}\').copy(destinationPath);\n  log.info(\'Saved vendored native bundle to $destinationPath\');\n  return;\n  final request = http.Request(\'GET\', Uri.parse(url));' \
            --replace-fail \
              "  final response = await http.get(Uri.parse(bundleSpec.releaseUrl));" \
              $'  await destination.writeAsBytes(await File(\'${litertLMNativeAndroidArm64}\').readAsBytes());\n  return;\n  final response = await http.get(Uri.parse(bundleSpec.releaseUrl));'
        done < <(${python3}/bin/python3 - <<'PY'
        import json
        import urllib.parse

        with open(".dart_tool/package_config.json") as f:
            data = json.load(f)

        for package in data.get("packages", []):
            if package.get("name") != "llamadart":
                continue
            root_uri = package.get("rootUri", "")
            if root_uri.startswith("file://"):
                print(urllib.parse.unquote(root_uri[len("file://"):]))
            elif root_uri.startswith("/"):
                print(root_uri)
        PY
        )
      '';

      buildPhase = ''
        runHook preBuild
        flutter build apk --release --no-pub --target-platform android-arm64
        runHook postBuild
      '';

      installPhase = ''
        runHook preInstall
        install -Dm644 build/app/outputs/flutter-apk/app-release.apk \
          "$out/meshcore-open.apk"
        runHook postInstall
      '';

      meta = with lib; {
        description = "MeshCore Open Android client built from source";
        homepage = "https://github.com/zjs81/meshcore-open";
        license = licenses.mit;
        platforms = platforms.unix;
      };
    });
in
mk-apk-package {
  inherit appPackage;
  mainApk = "meshcore-open.apk";
  signScriptName = "sign-meshcore-open";
  fdroid = {
    appId = "com.meshcore.meshcore_open";
    metadataYml = ''
      Categories:
        - Internet
      License: MIT
      SourceCode: https://github.com/zjs81/meshcore-open
      IssueTracker: https://github.com/zjs81/meshcore-open/issues
      AutoName: MeshCore Open
      Summary: Mesh networking client for MeshCore devices
      Description: |-
        MeshCore Open is an open-source client for MeshCore LoRa mesh
        networking devices, supporting messaging, channels, maps, and
        device management.
    '';
  };
}
