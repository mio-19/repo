{
  mk-apk-package,
  lib,
  jdk25,
  gradle-packages,
  stdenv,
  fetchFromGitHub,
  apksigner,
  writableTmpDirAsHomeHook,
  androidSdkBuilder,
  fetchpatch,
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

      gradle =
        (gradle-packages.mkGradle {
          version = "8.13";
          hash = "sha256-IPGxF2I3JUpvwgTYQ0GW+hGkz7OHVnUZxhVW6HEK7Xg=";
          defaultJava = jdk25;
        }).wrapped;
    in
    stdenv.mkDerivation (finalAttrs: {
      pname = "mastodon-android";
      version = "2.11.11-unstable-2026-04-04";

      src = fetchFromGitHub {
        owner = "mastodon";
        repo = "mastodon-android";
        #tag = "v${finalAttrs.version}";
        rev = "92478fa81dec9b6a8a272ffa55500e5526dcec74";
        hash = "sha256-gGDVNaGU/uMibPYB1+EcFBsYz5A/GIi+0gN6D1vbtRk=";
      };

      patches = [
        (fetchpatch {
          name = "Furigana implementation for japanese messages";
          url = "https://github.com/mastodon/mastodon-android/pull/1039.diff";
          hash = "sha256-QLD5iT2CXhiTVjXSLTqMtJ59rZ0GL7cKqvbytqxXs8A=";
        })
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
        jdk25
        apksigner
        writableTmpDirAsHomeHook
      ];

      env = {
        JAVA_HOME = jdk25;
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
        "-Dorg.gradle.java.installations.paths=${jdk25}"
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
