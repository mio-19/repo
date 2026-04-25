{
  mk-apk-package,
  lib,
  buildDartApplication,
  runCommand,
  fetchFromGitHub,
  flutter341,
  jdk17_headless,
  python3,
  gradle_8_13,
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
        s.ndk-28-2-13676358
        s.cmake-3-31-6
      ]);

      gradle = gradle_8_13;

      pythonWithYaml = python3.withPackages (ps: [ ps.pyyaml ]);
    in
    buildDartApplication.override { dart = flutter341; } (finalAttrs: {
      pname = "rain";
      version = "1.3.10";

      src = fetchFromGitHub {
        owner = "darkmoonight";
        repo = "Rain";
        tag = "v${finalAttrs.version}";
        hash = "sha256-j7b7LzNpEmXBuMP5VqGN+ltzpFi8DTVsAij4aDTJA5Y=";
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
              '${flutter341}/packages/${name}' \
              '${flutter341}/bin/cache/pkg/${name}'; do
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
        ANDROID_NDK_HOME = "${androidSdk}/share/android-sdk/ndk/28.2.13676358";
        ANDROID_NDK_ROOT = "${androidSdk}/share/android-sdk/ndk/28.2.13676358";
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
        cp -LR ${flutter341} flutter-sdk
        chmod -R u+w flutter-sdk
        touch flutter-sdk/bin/cache/engine.realm # https://github.com/NixOS/nixpkgs/pull/500309#issuecomment-4192628176
        chmod +x flutter-sdk/bin/cache/artifacts/engine/linux-x64/font-subset # needed after nixpkgs b86751bc4085f48661017fa226dee99fab6c651b -> 01fbdeef22b76df85ea168fbfe1bfd9e63681b30

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
        substituteInPlace android/app/build.gradle \
          --replace-fail "ndkVersion = '29.0.14206865'" "ndkVersion = '28.2.13676358'"

      '';

      preConfigure = ''
        export ANDROID_USER_HOME="$HOME/.android"
        mkdir -p "$ANDROID_USER_HOME"

        echo "sdk.dir=${androidSdk}/share/android-sdk" > android/local.properties
        echo "cmake.dir=${androidSdk}/share/android-sdk/cmake/3.31.6" >> android/local.properties
        echo "ndk.dir=${androidSdk}/share/android-sdk/ndk/28.2.13676358" >> android/local.properties
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

        mkdir -p .dart-patched
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

        remap_dart_package() {
          local original_dir="$1"
          local package_name="$2"
          local patched_dir="$PWD/.dart-patched/$package_name"

          if [ -n "$original_dir" ] && [ -d "$original_dir" ]; then
            cp -LR "$original_dir" "$patched_dir"
            chmod -R u+w "$patched_dir"
            substituteInPlace .dart_tool/package_config.json \
              --replace-fail "$original_dir" "$patched_dir"
          fi
        }

        remap_dart_package "$JNI_DIR" jni
        remap_dart_package "$JNI_FLUTTER_DIR" jni_flutter

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
