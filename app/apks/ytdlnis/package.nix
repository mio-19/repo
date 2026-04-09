{
  mk-apk-package,
  lib,
  jdk21_headless,
  gradle_8_13,
  stdenv,
  fetchFromGitHub,
  apksigner,
  writableTmpDirAsHomeHook,
  androidSdkBuilder,
  fetchpatch,
}:
let
  version = "1.8.8";

  src = fetchFromGitHub {
    owner = "deniscerri";
    repo = "ytdlnis";
    tag = "v${version}";
    hash = "sha256-fDvi6MFPxSRyIULtqIJq2MSpDFKoH0aRM2zGPaD6f0A=";
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

      gradle = gradle_8_13;
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

      patches = [
        (fetchpatch {
          name = "Enable synchronous memory tagging";
          url = "https://github.com/deniscerri/ytdlnis/pull/1157.diff";
          hash = "sha256-Vj69EgOWZ7DbU3xNC1ytVn1xOthq2j25ktdEfn7ic3k=";
        })
      ];

      nativeBuildInputs = [
        gradle
        jdk21_headless
        apksigner
        writableTmpDirAsHomeHook
      ];

      env = {
        JAVA_HOME = jdk21_headless;
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
        "-Dorg.gradle.java.installations.paths=${jdk21_headless}"
        "-Dandroid.aapt2FromMavenOverride=${androidSdk}/share/android-sdk/build-tools/36.1.0/aapt2"
        "-Dorg.gradle.project.android.aapt2FromMavenOverride=${androidSdk}/share/android-sdk/build-tools/36.1.0/aapt2"
      ];

      installPhase = ''
        runHook preInstall

        apk_dir="app/build/outputs/apk/release"
        apk_name="$(sed -n 's/.*"outputFile"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' "$apk_dir/output-metadata.json" | head -n 1)"
        test -n "$apk_name"
        apk_path="$apk_dir/$apk_name"
        test -f "$apk_path"
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
