{
  mk-apk-package,
  lib,
  jdk21,
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
        # AGP 8.2.2 resolves aapt2 from build-tools 34.0.0.
        s.build-tools-34-0-0
      ]);

      gradle =
        (gradle-packages.mkGradle {
          version = "8.5";
          hash = "sha256-nZJnhwZqCBc56CAIWDOLSmnoN8OoIaM6yp2wndSkECY=";
          defaultJava = jdk21;
        }).wrapped;
    in
    stdenv.mkDerivation (finalAttrs: {
      pname = "mastodon-android";
      version = "2.9.7";

      src = fetchFromGitHub {
        owner = "mastodon";
        repo = "mastodon-android";
        tag = "v${finalAttrs.version}";
        hash = "sha256-t4J9C6tT5cLqDmbO8drjNwk4ThQ+ibTQcb/oUwvMDSY=";
      };

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
        jdk21
        apksigner
        writableTmpDirAsHomeHook
      ];

      env = {
        JAVA_HOME = jdk21;
        ANDROID_HOME = "${androidSdk}/share/android-sdk";
        ANDROID_SDK_ROOT = "${androidSdk}/share/android-sdk";
        ANDROID_AAPT2_FROM_MAVEN_OVERRIDE = "${androidSdk}/share/android-sdk/build-tools/34.0.0/aapt2";
      };

      preConfigure = ''
        export ANDROID_USER_HOME="$HOME/.android"
        mkdir -p "$ANDROID_USER_HOME"
        echo "sdk.dir=${androidSdk}/share/android-sdk" > local.properties
      '';

      gradleFlags = [
        "-Dorg.gradle.java.installations.auto-download=false"
        "-Dorg.gradle.java.installations.paths=${jdk21}"
        "-Dandroid.aapt2FromMavenOverride=${androidSdk}/share/android-sdk/build-tools/34.0.0/aapt2"
        "-Dorg.gradle.project.android.aapt2FromMavenOverride=${androidSdk}/share/android-sdk/build-tools/34.0.0/aapt2"
        "-Dandroid.suppressUnsupportedCompileSdk=35"
      ];

      installPhase = ''
        runHook preInstall
        install -Dm644 \
          mastodon/build/outputs/apk/githubRelease/release/mastodon-githubRelease-release-unsigned.apk \
          "$out/mastodon-android.apk"
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
