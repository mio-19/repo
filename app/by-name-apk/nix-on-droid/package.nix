{
  mk-apk-package,
  lib,
  jdk17_headless,
  gradle-packages,
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
        s.platforms-android-28
        s.platforms-android-30
        s.build-tools-30-0-3
        s.build-tools-33-0-2
        s.ndk-27-3-13750724
      ]);

      gradle =
        (gradle-packages.mkGradle {
          version = "7.5";
          hash = "sha256-y4fyIsVYW9RoOK1Nt4RjpcXz0zbl4rmNx8DFhlJzUcI=";
          defaultJava = jdk17_headless;
        }).wrapped;
    in
    stdenv.mkDerivation (finalAttrs: {
      pname = "nix-on-droid";
      version = "0.118.0_v0.3.7_nix";

      src = fetchFromGitHub {
        owner = "nix-community";
        repo = "nix-on-droid-app";
        rev = "e87b6091bffa7b6eafb1b59cc7824f5692441cd0";
        hash = "sha256-E1f5zcSkfiVa71uuvRxQ+FveXGPD81K68U2N9QAhpro=";
      };

      gradleBuildTask = ":app:assembleRelease";
      gradleUpdateTask = finalAttrs.gradleBuildTask;

      mitmCache = gradle.fetchDeps {
        inherit (finalAttrs) pname;
        pkg = finalAttrs.finalPackage;
        data = ./nix-on-droid_deps.json;
        silent = false;
        useBwrap = false;
      };

      nativeBuildInputs = [
        gradle
        jdk17_headless
        writableTmpDirAsHomeHook
      ];

      env = {
        JAVA_HOME = jdk17_headless;
        ANDROID_HOME = "${androidSdk}/share/android-sdk";
        ANDROID_SDK_ROOT = "${androidSdk}/share/android-sdk";
        ANDROID_NDK_ROOT = "${androidSdk}/share/android-sdk/ndk/27.3.13750724";
        ANDROID_AAPT2_FROM_MAVEN_OVERRIDE = "${androidSdk}/share/android-sdk/build-tools/33.0.2/aapt2";
        TERMUX_PACKAGE_VARIANT = "apt-android-7";
        TERMUX_SPLIT_APKS_FOR_RELEASE_BUILDS = "0";
        JITPACK_NDK_VERSION = "27.3.13750724";
      };

      preConfigure = ''
        export ANDROID_USER_HOME="$HOME/.android"
        mkdir -p "$ANDROID_USER_HOME"
        echo "sdk.dir=${androidSdk}/share/android-sdk" > local.properties
      '';

      gradleFlags = [
        "-xlintVitalRelease"
        "--no-daemon"
        "-Dorg.gradle.java.installations.auto-download=false"
        "-Dorg.gradle.java.installations.paths=${jdk17_headless}"
        "-Dandroid.aapt2FromMavenOverride=${androidSdk}/share/android-sdk/build-tools/33.0.2/aapt2"
        "-Dorg.gradle.project.android.aapt2FromMavenOverride=${androidSdk}/share/android-sdk/build-tools/33.0.2/aapt2"
      ];

      installPhase = ''
        runHook preInstall

        apk_path="$(echo app/build/outputs/apk/release/*.apk | awk '{print $1}')"
        install -Dm644 "$apk_path" "$out/nix-on-droid.apk"

        runHook postInstall
      '';

      meta = with lib; {
        description = "Nix-on-Droid terminal emulator app";
        homepage = "https://github.com/nix-community/nix-on-droid";
        license = licenses.mit;
        platforms = platforms.unix;
        sourceProvenance = with sourceTypes; [ fromSource ];
      };
    });
in
mk-apk-package {
  inherit appPackage;
  mainApk = "nix-on-droid.apk";
  signScriptName = "sign-nix-on-droid";
  fdroid = {
    appId = "com.termux.nix";
    metadataYml = ''
      Categories:
        - Development
      License: MIT
      WebSite: https://nix-on-droid.unboiled.info
      SourceCode: https://github.com/nix-community/nix-on-droid
      IssueTracker: https://github.com/nix-community/nix-on-droid/issues
      Name: Nix-on-Droid
      AutoName: Nix
      Description: |-
        Nix-on-Droid brings the Nix package manager to Android.

        This app is the terminal-emulator part, built from the
        `nix-on-droid-app` source repository that F-Droid uses for
        the `com.termux.nix` package.

        Nix-on-Droid uses a fork of the Termux application as its
        terminal emulator.
    '';
  };
}
