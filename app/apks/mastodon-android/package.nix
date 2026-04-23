{
  mk-apk-package,
  lib,
  jdk21_headless,
  gradle_8_13,
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
        s.build-tools-35-0-0
      ]);

      gradle = gradle_8_13;
    in
    stdenv.mkDerivation (finalAttrs: {
      pname = "mastodon-android";
      version = "2.11.11-unstable-2026-04-10";

      src = fetchFromGitHub {
        owner = "mastodon";
        repo = "mastodon-android";
        #tag = "v${finalAttrs.version}";
        rev = "d8309f0de3cf0b798bd8947ec1121850087a77cb";
        hash = "sha256-w0KtvR5w0U4AWkjk7FOnBlUMq6J7CCV461P82C2MKhw=";
      };

      patches = [
        ./0001-furigana-rebased.patch
        /*
          (fetchpatch {
            name = "Enable more comprehensive R8 optimizations (#1079)";
            url = "https://github.com/mastodon/mastodon-android/pull/1079.diff";
            hash = "sha256-8pcIg8Qmv30WCQJsrJOqvP20pCcfov4F9XZbOZVOS+Y=";
          })
        */
      ];

      gradleBuildTask = ":mastodon:assembleGithubRelease";
      gradleUpdateTask = finalAttrs.gradleBuildTask;

      mitmCache = gradle.fetchDeps {
        inherit (finalAttrs) pname;
        pkg = finalAttrs.finalPackage;
        data = ./mastodon-android_deps.json;
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
        ANDROID_AAPT2_FROM_MAVEN_OVERRIDE = "${androidSdk}/share/android-sdk/build-tools/35.0.0/aapt2";
      };

      preConfigure = ''
        export ANDROID_USER_HOME="$HOME/.android"
        mkdir -p "$ANDROID_USER_HOME"
        echo "sdk.dir=${androidSdk}/share/android-sdk" > local.properties
      '';

      gradleFlags = [
        "-Dorg.gradle.java.installations.auto-download=false"
        "-Dorg.gradle.java.installations.paths=${jdk21_headless}"
        "-Dandroid.aapt2FromMavenOverride=${androidSdk}/share/android-sdk/build-tools/35.0.0/aapt2"
        "-Dorg.gradle.project.android.aapt2FromMavenOverride=${androidSdk}/share/android-sdk/build-tools/35.0.0/aapt2"
        "-Dandroid.suppressUnsupportedCompileSdk=35"
      ];

      installPhase = ''
        runHook preInstall
        apk_path="mastodon/build/outputs/apk/githubRelease/mastodon-githubRelease.apk"
        install -Dm644 "$apk_path" "$out/mastodon-android.apk"
        runHook postInstall
      '';

      meta = with lib; {
        description = "Official Mastodon Android app (GitHub release flavor, unsigned)";
        homepage = "https://github.com/mastodon/mastodon-android";
        license = licenses.gpl3Only;
        platforms = platforms.unix;
      };
    });
in
mk-apk-package {
  inherit appPackage;
  mainApk = "mastodon-android.apk";
  signScriptName = "sign-mastodon-android";
  fdroid = {
    appId = "org.joinmastodon.android";
    metadataYml = ''
      Categories:
        - Internet
      License: GPL-3.0-only
      SourceCode: https://github.com/mastodon/mastodon-android
      IssueTracker: https://github.com/mastodon/mastodon-android/issues
      Changelog: https://github.com/mastodon/mastodon-android/releases
      AutoName: Mastodon
      Summary: Official Mastodon Android app
      Description: |-
        Mastodon is the official Android app for Mastodon servers.
        This package builds the upstream GitHub release flavor from source.
    '';
  };
}
