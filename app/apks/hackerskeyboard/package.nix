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
  # Upstream versionName is still v1.41.1. This rev is master, which includes
  # layout fixes landed after the 1.41.1 tag.
  rev = "9202d9d8b1d379f1a20edf08ed7e7149038c8e43";

  appPackage =
    let
      androidSdk = androidSdkBuilder (s: [
        s.cmdline-tools-latest
        s.platform-tools
        s.platforms-android-36
        s.build-tools-36-0-0
        s.ndk-28-2-13676358
        s.cmake-3-22-1
      ]);

      gradle = gradle_8_13;
    in
    stdenv.mkDerivation (finalAttrs: {
      pname = "hackerskeyboard";
      version = "1.41.1";

      src = fetchFromGitHub {
        owner = "klausw";
        repo = "hackerskeyboard";
        inherit rev;
        hash = "sha256-26Cf4x7pMNWxNxv2iv8dDUQCiwb9YfnBZQk9Ni3rCHE=";
      };

      patches = [ ./agp-8.13.patch ];

      gradleBuildTask = ":app:assembleRelease";
      gradleUpdateTask = finalAttrs.gradleBuildTask;

      mitmCache = gradle.fetchDeps {
        inherit (finalAttrs) pname;
        pkg = finalAttrs.finalPackage;
        data = ./hackerskeyboard_deps.json;
        silent = false;
        useBwrap = false;
      };

      nativeBuildInputs = [
        gradle
        jdk21_headless
        writableTmpDirAsHomeHook
      ];

      env = {
        JAVA_HOME = jdk21_headless.passthru.home;
        ANDROID_HOME = "${androidSdk}/share/android-sdk";
        ANDROID_SDK_ROOT = "${androidSdk}/share/android-sdk";
        ANDROID_NDK_HOME = "${androidSdk}/share/android-sdk/ndk/28.2.13676358";
        ANDROID_NDK_ROOT = "${androidSdk}/share/android-sdk/ndk/28.2.13676358";
        ANDROID_AAPT2_FROM_MAVEN_OVERRIDE = "${androidSdk}/share/android-sdk/build-tools/36.0.0/aapt2";
      };

      preConfigure = ''
        export ANDROID_USER_HOME="$HOME/.android"
        mkdir -p "$ANDROID_USER_HOME"
        echo "sdk.dir=${androidSdk}/share/android-sdk" > local.properties
        echo "cmake.dir=${androidSdk}/share/android-sdk/cmake/3.22.1" >> local.properties
      '';

      gradleFlags = [
        "-Dorg.gradle.java.installations.auto-download=false"
        "-Dorg.gradle.java.installations.paths=${jdk21_headless.passthru.home}"
        "-Dandroid.aapt2FromMavenOverride=${androidSdk}/share/android-sdk/build-tools/36.0.0/aapt2"
        "-Dorg.gradle.project.android.aapt2FromMavenOverride=${androidSdk}/share/android-sdk/build-tools/36.0.0/aapt2"
      ];

      installPhase = ''
        runHook preInstall
        apk_dir="app/build/outputs/apk/release"
        apk_name="$(sed -n 's/.*"outputFile"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' "$apk_dir/output-metadata.json" | head -n 1)"
        test -n "$apk_name"
        apk_path="$apk_dir/$apk_name"
        test -f "$apk_path"
        install -Dm644 "$apk_path" "$out/hackerskeyboard.apk"
        runHook postInstall
      '';

      meta = with lib; {
        sourceProvenance = with sourceTypes; [ fromSource ];
        description = "Hacker's Keyboard, a 5-row keyboard with arrow keys and modifier keys";
        homepage = "https://github.com/klausw/hackerskeyboard";
        license = licenses.asl20;
        platforms = platforms.unix;
      };
    });
in
mk-apk-package {
  inherit appPackage;
  mainApk = "hackerskeyboard.apk";
  signScriptName = "sign-hackerskeyboard";
  fdroid = {
    appId = "org.pocketworkstation.pckeyboard";
    metadataYml = ''
      Categories:
        - Writing
      License: Apache-2.0
      AuthorName: Klaus Weidner
      SourceCode: https://github.com/klausw/hackerskeyboard
      IssueTracker: https://github.com/klausw/hackerskeyboard/issues
      Changelog: https://github.com/klausw/hackerskeyboard/wiki/ReleaseNotes
      AutoName: Hacker's Keyboard
      Summary: Five-row keyboard with arrow keys, Tab, Ctrl, and Esc
      Description: |-
        Hacker's Keyboard is a software keyboard with a separate number row,
        punctuation in the usual places, and arrow keys. It is based on the
        AOSP Gingerbread keyboard and is especially useful for SSH and other
        full-keyboard workflows.
        This package builds the current master revision of v1.41.1 from source.
    '';
  };
}
