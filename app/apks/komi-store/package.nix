{
  mk-apk-package,
  lib,
  gradle_9_5_1,
  jdk17_headless,
  jdk21_headless,
  jdk25_headless,
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
        s.platforms-android-36
        s.build-tools-36-0-0
      ]);

      gradle = gradle_9_5_1;
    in
    stdenv.mkDerivation (finalAttrs: {
      pname = "komi-store";
      version = "1.9.2";

      src = fetchFromGitHub {
        owner = "kurikomi-labs";
        repo = "komi-store";
        rev = "v${finalAttrs.version}";
        hash = "sha256-oRGkXLoH8+bzy3NE2rdtW3qgqT2c+z2y0qmwosatAeg=";
      };

      patches = [
        ./fix-desugaring.patch
      ];

      postPatch = ''
        substituteInPlace settings.gradle.kts \
          --replace-fail 'id("org.gradle.toolchains.foojay-resolver-convention") version "1.0.0"' ""
      '';

      gradleBuildTask = ":composeApp:assembleRelease";
      gradleUpdateTask = finalAttrs.gradleBuildTask;

      mitmCache = gradle.fetchDeps {
        inherit (finalAttrs) pname;
        pkg = finalAttrs.finalPackage;
        data = ./komi-store_deps.json;
        silent = false;
        useBwrap = false;
      };

      nativeBuildInputs = [
        androidSdk
        gradle
        jdk21_headless
        writableTmpDirAsHomeHook
      ];

      env = {
        JAVA_HOME = jdk21_headless.passthru.home;
        ANDROID_HOME = "${androidSdk}/share/android-sdk";
        ANDROID_SDK_ROOT = "${androidSdk}/share/android-sdk";
        ANDROID_AAPT2_FROM_MAVEN_OVERRIDE = "${androidSdk}/share/android-sdk/build-tools/36.0.0/aapt2";
      };

      preConfigure = ''
        export ANDROID_USER_HOME="$HOME/.android"
        mkdir -p "$ANDROID_USER_HOME"
        echo "sdk.dir=${androidSdk}/share/android-sdk" > local.properties
      '';

      gradleFlags = [
        "--no-configuration-cache"
        "-Dorg.gradle.java.installations.auto-download=false"
        "-Dorg.gradle.java.installations.paths=${jdk17_headless.passthru.home},${jdk21_headless.passthru.home},${jdk25_headless.passthru.home}"
        "-Dandroid.aapt2FromMavenOverride=${androidSdk}/share/android-sdk/build-tools/36.0.0/aapt2"
        "-Dorg.gradle.project.android.aapt2FromMavenOverride=${androidSdk}/share/android-sdk/build-tools/36.0.0/aapt2"
      ];

      installPhase = ''
        runHook preInstall
        apk_path="composeApp/build/outputs/apk/release/composeApp-release-unsigned.apk"
        if [ ! -f "$apk_path" ]; then
          apk_path=$(find composeApp/build/outputs/apk/release -name "*.apk" | head -n 1)
        fi
        install -Dm644 "$apk_path" "$out/komi-store.apk"
        runHook postInstall
      '';

      meta = with lib; {
        description = "Komi Store Android App";
        homepage = "https://github.com/kurikomi-labs/komi-store";
        license = licenses.asl20;
        platforms = platforms.unix;
      };
    });
in
mk-apk-package {
  inherit appPackage;
  mainApk = "komi-store.apk";
  signScriptName = "sign-komi-store";
  fdroid = {
    appId = "zed.rainxch.githubstore";
    metadataYml = ''
      Categories:
        - App Store & Updater
      License: Apache-2.0
      SourceCode: https://github.com/kurikomi-labs/komi-store
      IssueTracker: https://github.com/kurikomi-labs/komi-store/issues
      AutoName: Komi Store
      Summary: Modern GitHub client
      Description: |-
        Komi Store is a modern GitHub client for Android.
    '';
  };
}
