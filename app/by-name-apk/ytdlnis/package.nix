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
  version = "unstable-2026-03-28";

  src = fetchFromGitHub {
    owner = "deniscerri";
    repo = "ytdlnis";
    rev = "87f9cf3f80a873e81da0252df18b1d8e7f84e099";
    hash = "sha256-PNK4O+bJmfXPndUB7SJiINuQ8upgW75t3qe0CmSDgAE=";
  };

  appPackage =
    let
      androidSdk = androidSdkBuilder (s: [
        s.cmdline-tools-latest
        s.platform-tools
        s.platforms-android-36
        s.build-tools-35-0-0
        s.build-tools-36-1-0
      ]);

      gradle =
        (gradle-packages.mkGradle {
          version = "8.13";
          hash = "sha256-IPGxF2I3JUpvwgTYQ0GW+hGkz7OHVnUZxhVW6HEK7Xg=";
          defaultJava = jdk21;
        }).wrapped;
    in
    stdenv.mkDerivation (finalAttrs: {
      pname = "ytdlnis";
      inherit version src;

      gradleBuildTask = ":app:assembleRelease";
      gradleUpdateTask = finalAttrs.gradleBuildTask;

      mitmCache = gradle.fetchDeps {
        inherit (finalAttrs) pname;
        pkg = finalAttrs.finalPackage;
        data = ./ytdlnis_deps.json;
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
        ANDROID_AAPT2_FROM_MAVEN_OVERRIDE = "${androidSdk}/share/android-sdk/build-tools/36.1.0/aapt2";
      };

      postPatch = ''
        substituteInPlace app/build.gradle \
          --replace-fail '            signingConfig signingConfigs.debug' '            signingConfig null'
      '';

      preConfigure = ''
        export ANDROID_USER_HOME="$HOME/.android"
        mkdir -p "$ANDROID_USER_HOME"
        echo "sdk.dir=${androidSdk}/share/android-sdk" > local.properties
        touch keystore.properties
      '';

      gradleFlags = [
        "-Dorg.gradle.java.installations.auto-download=false"
        "-Dorg.gradle.java.installations.paths=${jdk21}"
        "-Dandroid.aapt2FromMavenOverride=${androidSdk}/share/android-sdk/build-tools/36.1.0/aapt2"
        "-Dorg.gradle.project.android.aapt2FromMavenOverride=${androidSdk}/share/android-sdk/build-tools/36.1.0/aapt2"
      ];

      installPhase = ''
        runHook preInstall

        apk_path="$(find app/build/outputs/apk/release -type f -name '*universal*.apk' | head -n 1)"
        if [[ ! -f "$apk_path" ]]; then
          apk_path="$(find app/build/outputs/apk/release -type f -name '*.apk' | head -n 1)"
        fi
        test -n "$apk_path" && test -f "$apk_path"
        install -Dm644 "$apk_path" "$out/ytdlnis.apk"

        runHook postInstall
      '';

      meta = with lib; {
        description = "YTDLnis downloader app for Android built from source";
        homepage = "https://github.com/deniscerri/ytdlnis";
        license = licenses.gpl3Only;
        platforms = platforms.unix;
      };
    });
in
mk-apk-package {
  inherit appPackage;
  mainApk = "ytdlnis.apk";
  signScriptName = "sign-ytdlnis";
  fdroid = {
    appId = "com.deniscerri.ytdl";
    metadataYml = ''
      Categories:
        - Multimedia
        - Internet
      License: GPL-3.0-only
      SourceCode: https://github.com/deniscerri/ytdlnis
      IssueTracker: https://github.com/deniscerri/ytdlnis/issues
      Changelog: https://github.com/deniscerri/ytdlnis/blob/main/CHANGELOG.md
      AutoName: YTDLnis
      Summary: yt-dlp based video and audio downloader
      Description: |-
        YTDLnis is a free and open source video and audio downloader for Android
        based on yt-dlp.
        This package builds YTDLnis from source.
    '';
  };
}
