{
  mk-apk-package,
  lib,
  jdk17_headless,
  gradle_8_12_1,
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
        s.platforms-android-35
        s.platforms-android-36
        s.build-tools-35-0-0
        s.build-tools-36-0-0
      ]);

      gradle = gradle_8_12_1;
    in
    stdenv.mkDerivation (finalAttrs: {
      pname = "gamenative";
      version = "1.1.0";

      src = fetchFromGitHub {
        owner = "utkarshdalal";
        repo = "GameNative";
        tag = "v${finalAttrs.version}";
        hash = "sha256-72g1ghnQ2XZ6eBGJCmaUBFx2eVN05Hos/eUqP/Qrl7Q=";
      };

      patches = [
        ./disable-release-lint.patch
        ./fix-dependency-resolution.patch
      ];

      postPatch = ''
        substituteInPlace app/build.gradle.kts \
          --replace-fail '    ndkVersion = "27.3.13750724"' ""
      '';

      gradleBuildTask = ":app:assembleModernRelease";
      gradleUpdateTask = finalAttrs.gradleBuildTask;

      mitmCache = gradle.fetchDeps {
        inherit (finalAttrs) pname;
        pkg = finalAttrs.finalPackage;
        data = ./gamenative_deps.json;
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
        ANDROID_AAPT2_FROM_MAVEN_OVERRIDE = "${androidSdk}/share/android-sdk/build-tools/35.0.0/aapt2";
      };

      preConfigure = ''
        export ANDROID_USER_HOME="$HOME/.android"
        mkdir -p "$ANDROID_USER_HOME"
        echo "sdk.dir=${androidSdk}/share/android-sdk" > local.properties
      '';

      gradleFlags = [
        "-Dorg.gradle.java.installations.auto-download=false"
        "-Dorg.gradle.java.installations.paths=${jdk17_headless}"
        "-Dandroid.aapt2FromMavenOverride=${androidSdk}/share/android-sdk/build-tools/35.0.0/aapt2"
        "-Dorg.gradle.project.android.aapt2FromMavenOverride=${androidSdk}/share/android-sdk/build-tools/35.0.0/aapt2"
      ];

      installPhase = ''
        runHook preInstall
        apk_path="$(echo app/build/outputs/apk/modern/release/*.apk | awk '{print $1}')"
        install -Dm644 "$apk_path" "$out/gamenative.apk"
        runHook postInstall
      '';

      meta = with lib; {
        description = "Android launcher for running Windows games";
        homepage = "https://github.com/utkarshdalal/GameNative";
        license = licenses.gpl3Only;
        platforms = platforms.unix;
      };
    });
in
mk-apk-package {
  inherit appPackage;
  mainApk = "gamenative.apk";
  signScriptName = "sign-gamenative";
  fdroid = {
    appId = "app.gamenative";
    metadataYml = ''
      Categories:
        - Games
      License: GPL-3.0-only
      SourceCode: https://github.com/utkarshdalal/GameNative
      IssueTracker: https://github.com/utkarshdalal/GameNative/issues
      Changelog: https://github.com/utkarshdalal/GameNative/releases
      AutoName: GameNative
      Summary: Android launcher for running Windows games
      Description: |-
        GameNative is an Android launcher for running Windows games with
        integrated container, Steam, and compatibility-layer management.
        This package is built from source.
    '';
  };
}
