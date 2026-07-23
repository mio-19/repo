{
  mk-apk-package,
  lib,
  buildDartApplication,
  runCommand,
  fetchFromGitHub,
  flutter344,
  jdk17_headless,
  python3,
  gradle_8_13,
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
        s.platforms-android-34
        s.platforms-android-35
        s.platforms-android-36
        s.platforms-android-37-0
        s.build-tools-34-0-0
        s.build-tools-35-0-0
        s.build-tools-36-1-0
        s.build-tools-37-0-0
        # App uses 30; jni/jni_flutter plugins still declare 28.2.
        # Do not set ndk.dir in local.properties — let AGP pick per-module.
        s.ndk-28-2-13676358
        s.ndk-30-0-14904198
        s.cmake-3-31-6
      ]);

      gradle = gradle_8_13;
      androidSdkRoot = "${androidSdk}/share/android-sdk";
      aapt2 = "${androidSdkRoot}/build-tools/35.0.0/aapt2";
      pythonWithYaml = python3.withPackages (ps: [ ps.pyyaml ]);
    in
    buildDartApplication.override { dart = flutter344; } (finalAttrs: {
      pname = "rain";
      version = "1.3.19";

      src = fetchFromGitHub {
        owner = "darkmoonight";
        repo = "Rain";
        tag = "v${finalAttrs.version}";
        hash = "sha256-/4GbzTfMW9Vh7oIYPRoCylJJ2em96xS4uxNzzHWOxtM=";
      };

      patches = [
        ./fix-build.patch
        ./0001-nolint.patch
      ];

      pubspecLock = lib.importJSON ./pubspec.lock.json;
      gitHashes = lib.importJSON ./git-hashes.json;

      sdkSourceBuilders = {
        flutter = mkFlutterSdkSourceBuilder {
          inherit runCommand;
          flutter = flutter344;
        };
      };

      mitmCache = gradle.fetchDeps {
        inherit (finalAttrs) pname;
        attrPath = "apk_rain";
        pkg = finalAttrs.finalPackage;
        data = ./rain_deps.json;
        silent = false;
        useBwrap = false;
      };

      gradleUpdateTask = ":app:checkFlossReleaseAarMetadata :app:assembleFlossRelease :connectivity_plus:extractReleaseAnnotations :dynamic_system_colors:checkReleaseAarMetadata :workmanager_android:checkReleaseAarMetadata";

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
        setup_writable_flutter_sdk ${flutter344}
        setup_pinned_gradlew ${gradle}/bin/gradle
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
        GRADLE_OPTS="$GRADLE_OPTS -Dorg.gradle.java.installations.paths=${jdk17_headless.passthru.home}"
        GRADLE_OPTS="$GRADLE_OPTS -Dandroid.aapt2FromMavenOverride=${aapt2}"
        GRADLE_OPTS="$GRADLE_OPTS -Dorg.gradle.project.android.aapt2FromMavenOverride=${aapt2}"
        append_mitm_gradle_opts
        export FLUTTER_ROOT="$PWD/flutter-sdk"

        mkdir -p .dart-patched
        declare -A patched_pkg_dirs

        # jni native builds write under the package tree; clone out of the Nix store.
        ${python3}/bin/python3 - <<'PY' > dart_package_dirs.sh
        import json
        import shlex
        import urllib.parse

        wanted = {
            "jni": "JNI_DIR",
            "jni_flutter": "JNI_FLUTTER_DIR",
        }
        found = {env_name: "" for env_name in wanted.values()}

        with open(".dart_tool/package_config.json") as f:
            data = json.load(f)

        for pkg in data["packages"]:
            env_name = wanted.get(pkg["name"])
            if env_name:
                found[env_name] = urllib.parse.urlparse(pkg["rootUri"]).path.removesuffix("/.")

        for env_name, path in found.items():
            print(f"export {env_name}={shlex.quote(path)}")
        PY
        . ./dart_package_dirs.sh

        for pkg_var in JNI_DIR JNI_FLUTTER_DIR; do
          pkg_dir="''${!pkg_var}"
          [ -n "$pkg_dir" ] && [ -d "$pkg_dir" ] || continue
          ensure_writable_dart_package "$pkg_dir" >/dev/null
        done

        ${pythonWithYaml}/bin/python3 ${../_shared/generate-flutter-plugins.py}
      '';

      buildPhase = ''
        runHook preBuild
        flutter build apk --release --no-pub --flavor floss
        runHook postBuild
      '';

      installPhase = ''
        runHook preInstall
        install -Dm644 build/app/outputs/flutter-apk/app-floss-release.apk \
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
