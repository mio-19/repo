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
  fetchpatch,
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
      version = "2.11.11";

      src = fetchFromGitHub {
        owner = "mastodon";
        repo = "mastodon-android";
        tag = "v${finalAttrs.version}";
        hash = "sha256-ySy+KZrJYr4W4woSzXId6qJVzm//v542ROSHDaDtcSA=";
      };

      patches = [
        (fetchpatch {
          name = "Enable more comprehensive R8 optimizations (#1079)";
          url = "https://github.com/mastodon/mastodon-android/pull/1079.diff";
          hash = "sha256-8pcIg8Qmv30WCQJsrJOqvP20pCcfov4F9XZbOZVOS+Y=";
        })
        (fetchpatch {
          name = "Detect hashtag links just like the web UI does";
          url = "https://github.com/mastodon/mastodon-android/pull/960.diff";
          hash = "sha256-uMIWEO3/STqHsd/ooyDNWak14uuQwYt85uRdS1Ji9R8=";
        })
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
        apk_path="$(find mastodon/build/outputs/apk -type f -name '*-unsigned.apk' | head -n1)"
        test -n "$apk_path"
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
