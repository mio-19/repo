{
  mk-apk-package,
  lib,
  jdk17_headless,
  gradle-packages,
  stdenv,
  fetchFromGitHub,
  apksigner,
  writableTmpDirAsHomeHook,
  androidSdkBuilder,
}:
let
  appPackage =
    let
      androidSdk = androidSdkBuilder (s: [
        s.cmdline-tools-latest
        s.platform-tools
        s.platforms-android-35
        s.build-tools-35-0-0
      ]);

      gradle =
        (gradle-packages.mkGradle {
          version = "8.14.3";
          hash = "sha256-vXEQIhNJMGCVbsIp2Ua+7lcVjb2J0OYrkbyg+ixfNTE=";
          defaultJava = jdk17_headless;
        }).wrapped;
    in
    stdenv.mkDerivation (finalAttrs: {
      pname = "mpv-android";
      version = "2026-03-22";

      src = fetchFromGitHub {
        owner = "mpv-android";
        repo = "mpv-android";
        tag = finalAttrs.version;
        hash = "sha256-eYqJiDhIWafcrVzQFrpf8WvRjGQtNMfYINBg8u4S/xE=";
      };

      gradleBuildTask = ":app:assembleDefaultDebug";
      gradleUpdateTask = finalAttrs.gradleBuildTask;

      mitmCache = gradle.fetchDeps {
        inherit (finalAttrs) pname;
        pkg = finalAttrs.finalPackage;
        data = ./mpv-android_deps.json;
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
        ANDROID_AAPT2_FROM_MAVEN_OVERRIDE = "${androidSdk}/share/android-sdk/build-tools/35.0.0/aapt2";
      };

      postPatch = ''
        cat > local.properties <<LOCALPROPS
        sdk.dir=${androidSdk}/share/android-sdk
        LOCALPROPS
      '';

      gradleFlags = [
        "-Dandroid.builder.sdkDownload=false"
        "-Dorg.gradle.java.installations.auto-download=false"
        "-Dorg.gradle.java.installations.paths=${jdk17_headless}"
        "-Dandroid.aapt2FromMavenOverride=${androidSdk}/share/android-sdk/build-tools/35.0.0/aapt2"
        "-Dorg.gradle.project.android.aapt2FromMavenOverride=${androidSdk}/share/android-sdk/build-tools/35.0.0/aapt2"
      ];

      installPhase = ''
        runHook preInstall
        apk_path="$(find . -type f -name 'app-default-debug.apk' | head -n 1)"
        test -n "$apk_path" && test -f "$apk_path"
        install -Dm644 "$apk_path" "$out/mpv-android.apk"
        runHook postInstall
      '';

      meta = with lib; {
        description = "mpv for Android built from source";
        homepage = "https://github.com/mpv-android/mpv-android";
        license = licenses.gpl3Plus;
        platforms = platforms.unix;
      };
    });
in
mk-apk-package {
  inherit appPackage;
  mainApk = "mpv-android.apk";
  signScriptName = "sign-mpv-android";
  fdroid = {
    appId = "is.xyz.mpv";
    metadataYml = ''
      Categories:
        - Multimedia
      License: GPL-3.0-or-later
      SourceCode: https://github.com/mpv-android/mpv-android
      IssueTracker: https://github.com/mpv-android/mpv-android/issues
      Changelog: https://github.com/mpv-android/mpv-android/releases
      AutoName: mpv-android
      Summary: Video player based on libmpv
      Description: |-
        mpv-android is a video player for Android based on libmpv.
        This package is built from source.
    '';
  };
}
