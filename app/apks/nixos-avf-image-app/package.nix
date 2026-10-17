{
  mk-apk-package,
  lib,
  gradle_8_13,
  jdk21_headless,
  stdenv,
  fetchFromGitHub,
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
        s.build-tools-36-0-0
      ]);

      gradle = gradle_8_13;
    in
    stdenv.mkDerivation (finalAttrs: {
      pname = "nixos-avf-image-app";
      version = "0.3.1-unstable-2026-03-25";

      src = fetchFromGitHub {
        owner = "nix-community";
        repo = "nixos-avf-image-app";
        rev = "d75282ac722feec71b374594f09a7d3a5e97bf3f";
        hash = "sha256-w5yIl47kDN6/OB89j7z2dMnnQF/JzX1ui3ZXAX4miYQ=";
      };

      patches = [
        ./0001-show-debug-install-method.patch
      ];

      postPatch = ''
        substituteInPlace app/build.gradle.kts \
          --replace-fail 'compileSdk = 36' 'compileSdk = 36; buildToolsVersion = "36.0.0"' \
          --replace-fail 'includeSourceContext.set(true)' 'includeSourceContext.set(false); autoUploadProguardMapping.set(false); telemetry.set(false)'
        echo "-dontwarn androidx.window.**" >> app/proguard-rules.pro
        echo "-dontwarn androidx.core.text.**" >> app/proguard-rules.pro
        echo "-dontwarn io.sentry.**" >> app/proguard-rules.pro
      '';

      gradleBuildTask = ":app:assembleRelease";
      gradleUpdateTask = finalAttrs.gradleBuildTask;

      mitmCache = gradle.fetchDeps {
        inherit (finalAttrs) pname;
        pkg = finalAttrs.finalPackage;
        data = ./nixos_avf_image_app_deps.json;
        silent = false;
        useBwrap = false;
      };

      nativeBuildInputs = [
        gradle
        jdk21_headless
        writableTmpDirAsHomeHook
      ];

      env = {
        JAVA_HOME = jdk21_headless;
        ANDROID_HOME = "${androidSdk}/share/android-sdk";
        ANDROID_SDK_ROOT = "${androidSdk}/share/android-sdk";
        ANDROID_AAPT2_FROM_MAVEN_OVERRIDE = "${androidSdk}/share/android-sdk/build-tools/36.0.0/aapt2";
        SENTRY_DISABLE_TELEMETRY = "true";
        SENTRY_TELEMETRY_DISABLE = "true";
      };

      preConfigure = ''
        export ANDROID_USER_HOME="$HOME/.android"
        mkdir -p "$ANDROID_USER_HOME"
        echo "sdk.dir=${androidSdk}/share/android-sdk" > local.properties
        printf "\nsentry.telemetry=false\n" >> gradle.properties
      '';

      gradleFlags = [
        "-xuploadSentryProguardMappingsRelease"
        "-Psentry.telemetry=false"
        "-Dsentry.telemetry=false"
        "-Dorg.gradle.java.installations.auto-download=false"
        "-Dorg.gradle.java.installations.paths=${jdk21_headless}"
        "-Dandroid.builder.sdkDownload=false"
        "-Dio.sentry.telemetry.enabled=false"
        "-Dsentry.telemetry.enabled=false"
        "-Dio.sentry.auto-init=false"
        "-Dsentry.auto-init=false"
        "-Dandroid.aapt2FromMavenOverride=${androidSdk}/share/android-sdk/build-tools/36.0.0/aapt2"
        "-Dorg.gradle.project.android.aapt2FromMavenOverride=${androidSdk}/share/android-sdk/build-tools/36.0.0/aapt2"
      ];

      installPhase = ''
        runHook preInstall
        apk_path="$(echo app/build/outputs/apk/release/*-release-unsigned.apk)"
        install -Dm644 "$apk_path" "$out/nixos-avf-image-app.apk"
        runHook postInstall
      '';

      meta = with lib; {
        sourceProvenance = with sourceTypes; [ fromSource ];
        description = "NixOS Image Installer for Android Terminal app (unsigned APK)";
        homepage = "https://github.com/nix-community/nixos-avf-image-app";
        license = licenses.gpl3Only;
        platforms = platforms.unix;
      };
    });
in
mk-apk-package {
  inherit appPackage;
  mainApk = "nixos-avf-image-app.apk";
  signScriptName = "sign-nixos-avf-image-app";
  fdroid = {
    appId = "io.mkg20001.nixosimage";
    metadataYml = ''
      Categories:
        - System
      License: GPL-3.0-only
      SourceCode: https://github.com/nix-community/nixos-avf-image-app
      IssueTracker: https://github.com/nix-community/nixos-avf-image-app/issues
      AutoName: NixOS Image Installer
      Summary: NixOS Image Installer for Android Terminal
      Description: |-
        NixOS Image Installer helps download and install NixOS images for Android Terminal app.
        This package is built from source.
    '';
  };
}
