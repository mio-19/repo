{
  mk-apk-package,
  lib,
  jdk21,
  jdk17_headless,
  gradle-packages,
  stdenv,
  fetchFromGitea,
  apksigner,
  writableTmpDirAsHomeHook,
  androidSdkBuilder,
  git,
}:
let
  appPackage =
    let
      androidSdk = androidSdkBuilder (s: [
        s.cmdline-tools-latest
        s.platform-tools
        s.platforms-android-36
        s.build-tools-35-0-0
      ]);

      gradle =
        (gradle-packages.mkGradle {
          version = "8.13";
          hash = "sha256-IPGxF2I3JUpvwgTYQ0GW+hGkz7OHVnUZxhVW6HEK7Xg=";
          defaultJava = jdk21;
        }).wrapped;
    in
    stdenv.mkDerivation (finalAttrs: {
      pname = "sunup";
      version = "1.3.1";

      src = fetchFromGitea {
        domain = "codeberg.org";
        owner = "Sunup";
        repo = "android";
        rev = finalAttrs.version;
        hash = "sha256-9KoM8a8sMvN0zNv5gXPZDOjv1U+oI5WA/w2Ilcdn/mI=";
      };

      gradleBuildTask = ":app:assembleRelease";
      gradleUpdateTask = finalAttrs.gradleBuildTask;

      mitmCache = gradle.fetchDeps {
        inherit (finalAttrs) pname;
        pkg = finalAttrs.finalPackage;
        data = "sunup_deps.json";
        silent = false;
        useBwrap = false;
      };

      nativeBuildInputs = [
        gradle
        jdk17_headless
        apksigner
        writableTmpDirAsHomeHook
        git
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
        "-xlintVitalRelease"
        "-Dorg.gradle.java.installations.auto-download=false"
        "-Dorg.gradle.java.installations.paths=${jdk17_headless},${jdk21}"
        "-Dandroid.aapt2FromMavenOverride=${androidSdk}/share/android-sdk/build-tools/35.0.0/aapt2"
        "-Dorg.gradle.project.android.aapt2FromMavenOverride=${androidSdk}/share/android-sdk/build-tools/35.0.0/aapt2"
      ];

      installPhase = ''
        runHook preInstall
        apk_path="$(echo app/build/outputs/apk/release/*.apk)"
        install -Dm644 "$apk_path" "$out/sunup.apk"
        runHook postInstall
      '';

      meta = with lib; {
        description = "UnifiedPush distributor using a local push gateway";
        homepage = "https://codeberg.org/Sunup/android";
        license = licenses.gpl3Plus;
        platforms = platforms.unix;
      };
    });
in
mk-apk-package {
  inherit appPackage;
  mainApk = "sunup.apk";
  signScriptName = "sign-sunup";
  fdroid = {
    appId = "org.unifiedpush.distributor.sunup";
    metadataYml = ''
      Categories:
        - System
      License: GPL-3.0-or-later
      SourceCode: https://codeberg.org/Sunup/android
      IssueTracker: https://codeberg.org/Sunup/android/issues
      AutoName: Sunup
      Summary: UnifiedPush distributor using a local push gateway
      Description: |-
        Sunup is a UnifiedPush distributor that uses a local push gateway
        to deliver push notifications without relying on Google services.
        This package is built from source.
    '';
  };
}
