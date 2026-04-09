{
  mk-apk-package,
  lib,
  stdenv,
  fetchFromGitHub,
  fetchzip,
  runCommand,
  androidSdkBuilder,
  gradle_9_3_1,
  jdk17_headless,
  apksigner,
  writableTmpDirAsHomeHook,
  bison,
  python3,
  gcc,
}:
let
  appPackage =
    let
      rev = "3376f0ed5f5c7cf4ba960df218a00c6cc053ffb7";
      shortRev = builtins.substring 0 7 rev;
      version = "unstable-2026-02-18";

      src = fetchFromGitHub {
        owner = "termux";
        repo = "termux-x11";
        inherit rev;
        fetchSubmodules = true;
        hash = "sha256-/S5tja9wFN2/XjNSxhIDIU6CY80W9MUAIPQ8aLtR9uk=";
      };

      androidSdk = androidSdkBuilder (s: [
        s.cmdline-tools-latest
        s.platform-tools
        s.platforms-android-34
        s.build-tools-34-0-0
        s.build-tools-36-0-0
        s.ndk-29-0-14206865
        s.cmake-3-31-6
      ]);

      gradle = gradle_9_3_1;
    in
    stdenv.mkDerivation (finalAttrs: {
      pname = "termux-x11";
      inherit version;
      inherit src;

      gradleBuildTask = ":app:assembleDebug";
      gradleUpdateTask = finalAttrs.gradleBuildTask;

      mitmCache = gradle.fetchDeps {
        inherit (finalAttrs) pname;
        pkg = finalAttrs.finalPackage;
        data = ./termux-x11_deps.json;
        silent = false;
        useBwrap = false;
      };

      nativeBuildInputs = [
        gradle
        jdk17_headless
        apksigner
        writableTmpDirAsHomeHook
        bison
        python3
        gcc
      ];

      env = {
        JAVA_HOME = if stdenv.isDarwin then "${jdk17_headless}" else "${jdk17_headless}/lib/openjdk";
        ANDROID_HOME = "${androidSdk}/share/android-sdk";
        ANDROID_SDK_ROOT = "${androidSdk}/share/android-sdk";
        ANDROID_NDK_ROOT = "${androidSdk}/share/android-sdk/ndk/29.0.14206865";
        ANDROID_AAPT2_FROM_MAVEN_OVERRIDE = "${androidSdk}/share/android-sdk/build-tools/36.0.0/aapt2";
        CURRENT_COMMIT = rev;
      };

      postPatch = ''
        substituteInPlace app/build.gradle \
          --replace-fail "    compileSdkVersion 34
        " "    compileSdkVersion 34
            ndkVersion \"29.0.14206865\"
        "

        substituteInPlace app/build.gradle \
          --replace-fail "def commit= 'git rev-parse --verify --short HEAD'.execute().text.trim()" "def commit = System.getenv('TERMUX_X11_GIT_SHORT_COMMIT') ?: '${shortRev}'" \
          --replace-fail '-''${commit.length()==1?"nongit":commit}-''${(new Date()).format("dd.MM.yy")}' '+git.''${commit}' \
          --replace-fail "\"\\\"\" + (\"git rev-parse HEAD\\n\".execute().getText().trim() ?: (System.getenv('CURRENT_COMMIT') ?: \"NO_COMMIT\")) + \"\\\"\"" "\"\\\"\" + (System.getenv('CURRENT_COMMIT') ?: \"${rev}\") + \"\\\"\""

        substituteInPlace shell-loader/build.gradle \
          --replace-fail "\"\\\"\" + (\"git rev-parse HEAD\\n\".execute().getText().trim() ?: (System.getenv('CURRENT_COMMIT') ?: \"NO_COMMIT\")) + \"\\\"\"" "\"\\\"\" + (System.getenv('CURRENT_COMMIT') ?: \"${rev}\") + \"\\\"\""

        substituteInPlace app/src/main/cpp/recipes/xkbcomp.cmake \
          --replace-fail 'COMMAND "/usr/bin/gcc"' 'COMMAND "${gcc}/bin/gcc"'
      '';

      preConfigure = ''
        export ANDROID_USER_HOME="$HOME/.android"
        mkdir -p "$ANDROID_USER_HOME"
        echo "sdk.dir=${androidSdk}/share/android-sdk" > local.properties
        echo "cmake.dir=${androidSdk}/share/android-sdk/cmake/3.31.6" >> local.properties
      '';

      gradleFlags = [
        "-xlintVitalRelease"
        "-Dorg.gradle.java.installations.auto-download=false"
        "-Dorg.gradle.java.installations.paths=${finalAttrs.env.JAVA_HOME}"
        "-Dandroid.aapt2FromMavenOverride=${androidSdk}/share/android-sdk/build-tools/36.0.0/aapt2"
        "-Dorg.gradle.project.android.aapt2FromMavenOverride=${androidSdk}/share/android-sdk/build-tools/36.0.0/aapt2"
        "-Dorg.gradle.jvmargs=-Xmx4096m"
      ];

      TERMUX_X11_GIT_SHORT_COMMIT = shortRev;

      installPhase = ''
        runHook preInstall
        install -Dm644 app/build/outputs/apk/debug/app-universal-debug.apk "$out/termux-x11.apk"
        runHook postInstall
      '';

      meta = with lib; {
        description = "Termux X11 server add-on app built from source";
        homepage = "https://github.com/termux/termux-x11";
        license = licenses.gpl3Only;
        platforms = platforms.linux;
      };
    });
in
mk-apk-package {
  inherit appPackage;
  mainApk = "termux-x11.apk";
  signScriptName = "sign-termux-x11";
  fdroid = {
    appId = "com.termux.x11";
    metadataYml = ''
      Categories:
        - Development
      License: GPL-3.0-only
      WebSite: https://termux.com
      SourceCode: https://github.com/termux/termux-x11
      IssueTracker: https://github.com/termux/termux-x11/issues
      Changelog: https://github.com/termux/termux-x11/releases/tag/nightly
      Donate: https://termux.com/donate.html
      OpenCollective: Termux
      AutoName: Termux:X11
      Summary: X11 server add-on for Termux
      Description: |-
        Termux:X11 is the X11 server companion app for Termux.
        This package is built from source from the upstream master
        branch at commit 3376f0ed5f5c7cf4ba960df218a00c6cc053ffb7.

        F-Droid does not currently ship metadata for this application,
        so this repo follows the upstream nightly debug universal APK
        build layout instead.
    '';
  };
}
