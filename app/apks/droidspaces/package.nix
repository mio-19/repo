{
  mk-apk-package,
  lib,
  jdk17_headless,
  stdenv,
  fetchFromGitHub,
  apksigner,
  writableTmpDirAsHomeHook,
  androidSdkBuilder,
  pkgsCross,
  applyPatches,
  gradle_8_2,
}:
let
  appPackage =
    let
      version = "5.9.0";

      srcBase = fetchFromGitHub {
        owner = "ravindu644";
        repo = "Droidspaces-OSS";
        tag = "v${version}";
        hash = "sha256-eqwGBHYuW57k0xW8O5ifH3CUR8Jdo/QSF/KJzPjlkoc=";
      };

      androidSdk = androidSdkBuilder (s: [
        s.cmdline-tools-latest
        s.platform-tools
        s.platforms-android-34
        s.build-tools-34-0-0
      ]);

      gradle = gradle_8_2;

      mkDroidspacesStatic =
        {
          crossPkgs,
          suffix,
        }:
        crossPkgs.pkgsStatic.stdenv.mkDerivation {
          pname = "droidspaces-${suffix}";
          inherit version srcBase;
          src = srcBase;

          enableParallelBuilding = true;

          buildPhase = ''
            runHook preBuild
            make droidspaces CC="$CC"
            runHook postBuild
          '';

          installPhase = ''
            runHook preInstall
            install -Dm755 output/droidspaces "$out/bin/droidspaces-${suffix}"
            runHook postInstall
          '';

          meta.mainProgram = "droidspaces-${suffix}";
        };

      droidspacesAarch64 = mkDroidspacesStatic {
        crossPkgs = pkgsCross.aarch64-multiplatform;
        suffix = "aarch64";
      };

      droidspacesArmhf = mkDroidspacesStatic {
        crossPkgs = pkgsCross.armv7l-hf-multiplatform;
        suffix = "armhf";
      };

      droidspacesX86 = mkDroidspacesStatic {
        crossPkgs = pkgsCross.gnu32;
        suffix = "x86";
      };

      droidspacesX8664 = mkDroidspacesStatic {
        crossPkgs = pkgsCross.gnu64;
        suffix = "x86_64";
      };
    in
    stdenv.mkDerivation (finalAttrs: {
      pname = "droidspaces-oss";
      inherit version;

      src = applyPatches {
        src = srcBase;
        postPatch = ''
          cp ${lib.getExe' droidspacesAarch64 "droidspaces-aarch64"} Android/app/src/main/assets/binaries/droidspaces-aarch64
          cp ${lib.getExe' droidspacesArmhf "droidspaces-armhf"} Android/app/src/main/assets/binaries/droidspaces-armhf
          cp ${lib.getExe' droidspacesX86 "droidspaces-x86"} Android/app/src/main/assets/binaries/droidspaces-x86
          cp ${lib.getExe' droidspacesX8664 "droidspaces-x86_64"} Android/app/src/main/assets/binaries/droidspaces-x86_64
          rm Android/app/src/main/assets/binaries/busybox-aarch64
          cp ${lib.getExe pkgsCross.aarch64-multiplatform.pkgsStatic.busybox} Android/app/src/main/assets/binaries/busybox-aarch64
          rm Android/app/src/main/assets/binaries/busybox-armhf
          cp ${lib.getExe pkgsCross.armv7l-hf-multiplatform.pkgsStatic.busybox} Android/app/src/main/assets/binaries/busybox-armhf
          rm Android/app/src/main/assets/binaries/busybox-x86
          cp ${lib.getExe pkgsCross.gnu32.pkgsStatic.busybox} Android/app/src/main/assets/binaries/busybox-x86
          rm Android/app/src/main/assets/binaries/busybox-x86_64
          cp ${lib.getExe pkgsCross.gnu64.pkgsStatic.busybox} Android/app/src/main/assets/binaries/busybox-x86_64
        '';
      };

      sourceRoot = "${finalAttrs.src.name}/Android";

      gradleBuildTask = ":app:assembleRelease";
      gradleUpdateTask = finalAttrs.gradleBuildTask;

      # Lock refresh steps:
      # 1. If Droidspaces bumps Gradle, update `gradle.version` and `gradle.hash`.
      # 2. Build the updater:
      #    nix build --impure .#droidspaces-oss.mitmCache.updateScript
      # 3. Run the resulting `fetch-deps.sh` from the repo root to regenerate
      #    app/droidspaces-oss/droidspaces-oss_deps.json.
      mitmCache = gradle.fetchDeps {
        inherit (finalAttrs) pname;
        pkg = finalAttrs.finalPackage;
        data = ./droidspaces-oss_deps.json;
        silent = false;
        useBwrap = false;
      };

      nativeBuildInputs = [
        gradle
        jdk17_headless
        apksigner
        writableTmpDirAsHomeHook
      ];

      env = {
        JAVA_HOME = jdk17_headless;
        ANDROID_HOME = "${androidSdk}/share/android-sdk";
        ANDROID_SDK_ROOT = "${androidSdk}/share/android-sdk";
        ANDROID_AAPT2_FROM_MAVEN_OVERRIDE = "${androidSdk}/share/android-sdk/build-tools/34.0.0/aapt2";
      };

      postPatch = ''
        substituteInPlace app/build.gradle.kts \
          --replace-fail \
          'var fallbackKeystore = file(System.getProperty("user.home") + "/.android/debug.keystore")' \
          'var fallbackKeystore = file((System.getenv("ANDROID_USER_HOME") ?: (System.getProperty("user.home") + "/.android")) + "/debug.keystore")'
      '';

      preConfigure = ''
        export ANDROID_USER_HOME="$HOME/.android"
        mkdir -p "$ANDROID_USER_HOME"
        echo "sdk.dir=${androidSdk}/share/android-sdk" > local.properties
        if [ ! -f "$ANDROID_USER_HOME/debug.keystore" ]; then
          keytool -genkeypair \
            -alias androiddebugkey \
            -keyalg RSA \
            -keysize 2048 \
            -validity 10000 \
            -storetype JKS \
            -keystore "$ANDROID_USER_HOME/debug.keystore" \
            -storepass android \
            -keypass android \
            -dname "CN=Android Debug,O=Android,C=US"
        fi
      '';

      gradleFlags = [
        "-xlintVitalRelease"
        "-Dorg.gradle.java.installations.auto-download=false"
        "-Dorg.gradle.java.installations.paths=${jdk17_headless}"
        "-Dandroid.aapt2FromMavenOverride=${androidSdk}/share/android-sdk/build-tools/34.0.0/aapt2"
        "-Dorg.gradle.project.android.aapt2FromMavenOverride=${androidSdk}/share/android-sdk/build-tools/34.0.0/aapt2"
      ];

      installPhase = ''
        runHook preInstall
        install -Dm644 \
          app/build/outputs/apk/release/app-release.apk \
          "$out/droidspaces-oss.apk"
        runHook postInstall
      '';

      meta = with lib; {
        description = "Droidspaces Android app";
        homepage = "https://github.com/ravindu644/Droidspaces-OSS";
        license = licenses.gpl3Only;
        platforms = platforms.unix;
      };
    });
in
mk-apk-package {
  inherit appPackage;
  mainApk = "droidspaces-oss.apk";
  signScriptName = "sign-droidspaces-oss";
  fdroid = {
    appId = "com.droidspaces.app";
    metadataYml = ''
      Categories:
        - System
      License: GPL-3.0-only
      SourceCode: https://github.com/ravindu644/Droidspaces-OSS
      IssueTracker: https://github.com/ravindu644/Droidspaces-OSS/issues
      AutoName: Droidspaces
      Summary: Containerized Linux workspace plus terminal for Android
      Description: |-
        Droidspaces launches pre-configured Linux containers, terminals,
        and utilities directly on Android. The build here matches upstream
        source artifacts.
    '';
  };
}
