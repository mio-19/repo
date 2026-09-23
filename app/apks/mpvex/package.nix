{
  mk-apk-package,
  lib,
  jdk17_headless,
  gradle_9_6_1,
  stdenv,
  fetchFromGitHub,

  writableTmpDirAsHomeHook,
  androidSdkBuilder,
  git,
}:
let
  rev = "7158a02";

  appPackage =
    let
      androidSdk = androidSdkBuilder (s: [
        s.cmdline-tools-latest
        s.platform-tools
        s.platforms-android-37-0
        s.build-tools-36-0-0
      ]);

      gradle = gradle_9_6_1;
    in
    stdenv.mkDerivation (finalAttrs: {
      pname = "mpvex";
      version = "unstable-2026-03-21";

      src = fetchFromGitHub {
        owner = "marlboro-advance";
        repo = "mpvEx";
        inherit rev;
        hash = "sha256-52p7ULl0VMegtbflKNvwcLgvvqO1VrDBMBZa4sQbSmI=";
      };

      gradleBuildTask = ":app:assembleFdroidRelease";
      gradleUpdateTask = finalAttrs.gradleBuildTask;

      mitmCache = gradle.fetchDeps {
        inherit (finalAttrs) pname;
        pkg = finalAttrs.finalPackage;
        data = ./mpvex_deps.json;
        silent = false;
        useBwrap = false;
      };

      nativeBuildInputs = [
        gradle
        jdk17_headless

        writableTmpDirAsHomeHook
        git
      ];

      env = {
        JAVA_HOME = jdk17_headless;
        ANDROID_HOME = "${androidSdk}/share/android-sdk";
        ANDROID_SDK_ROOT = "${androidSdk}/share/android-sdk";
        ANDROID_AAPT2_FROM_MAVEN_OVERRIDE = "${androidSdk}/share/android-sdk/build-tools/36.0.0/aapt2";
      };

      postPatch = ''
        substituteInPlace app/build.gradle.kts \
          --replace-fail 'runCommand("git rev-list --count HEAD") ?: "0"' '"129"' \
          --replace-fail 'runCommand("git rev-parse --short HEAD") ?: "unknown"' '"${lib.substring 0 7 rev}"'
      '';

      preConfigure = ''
        export ANDROID_USER_HOME="$HOME/.android"
        mkdir -p "$ANDROID_USER_HOME"
        echo "sdk.dir=${androidSdk}/share/android-sdk" > local.properties
      '';

      gradleFlags = [
        "-Dorg.gradle.java.installations.auto-download=false"
        "-Dorg.gradle.java.installations.paths=${jdk17_headless}"
        "-Dandroid.aapt2FromMavenOverride=${androidSdk}/share/android-sdk/build-tools/36.0.0/aapt2"
        "-Dorg.gradle.project.android.aapt2FromMavenOverride=${androidSdk}/share/android-sdk/build-tools/36.0.0/aapt2"
      ];

      installPhase = ''
        runHook preInstall
        apkDir="app/build/outputs/apk/fdroid/release"
        apkName="$(sed -n 's/.*"outputFile"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' "$apkDir/output-metadata.json" | head -n 1)"
        test -n "$apkName"
        apkPath="$apkDir/$apkName"
        test -f "$apkPath"
        install -Dm644 "$apkPath" "$out/mpvex.apk"
        runHook postInstall
      '';

      meta = with lib; {
        description = "mpvExtended Android player built from source";
        homepage = "https://github.com/marlboro-advance/mpvEx";
        license = licenses.gpl2Plus;
        platforms = platforms.unix;
      };
    });
in
mk-apk-package {
  inherit appPackage;
  mainApk = "mpvex.apk";
  signScriptName = "sign-mpvex";
  fdroid = {
    appId = "app.marlboroadvance.mpvex";
    metadataYml = ''
      Categories:
        - Multimedia
      License: GPL-2.0-or-later
      SourceCode: https://github.com/marlboro-advance/mpvEx
      IssueTracker: https://github.com/marlboro-advance/mpvEx/issues
      Changelog: https://github.com/marlboro-advance/mpvEx/releases
      AutoName: mpvExtended
      Summary: Feature-rich mpv-based media player
      Description: |-
        mpvExtended is an Android media player based on mpv.
        This package builds the upstream F-Droid flavor from source.
    '';
  };
}
