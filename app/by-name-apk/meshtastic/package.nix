{
  mk-apk-package,
  lib,
  gradle_9_3_1,
  jdk25,
  jdk17_headless,
  stdenv,
  fetchFromGitHub,
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
        s.build-tools-36-0-0
      ]);

      gradle = gradle_9_3_1;
    in
    stdenv.mkDerivation (finalAttrs: {
      pname = "meshtastic";
      version = "2.7.13";

      src = fetchFromGitHub {
        owner = "meshtastic";
        repo = "Meshtastic-Android";
        rev = "v${finalAttrs.version}";
        hash = "sha256-bktrjU/KgUeh4eLPfQM3No1oK5YOo3bjRHRk+qGg4X8=";
        fetchSubmodules = true;
      };

      patches = [
        ./0001-checkReleaseBuilds-false.patch
        # Remove foojay JDK auto-provisioner (prevents network access in sandbox).
        # Must be first: later patches assume this line is already gone.
        ./remove-foojay.patch
        # Remove develocity build-scan plugin (not needed for building,
        # and causes class-load errors with Gradle 9.3.1)
        ./remove-develocity.patch
        # Pin kotlin-dsl to 6.4.2 in build-logic; 5.2.0 is bundled with
        # Gradle 9.3.1 and not published to Maven.
        ./pin-kotlin-dsl.patch
        # Remove firebase plugin declarations (unneeded for fdroid flavor)
        ./remove-firebase-root.patch
        ./remove-firebase-convention.patch
        # Remove firebase-crashlytics apply() and plugins.withId block from
        # AnalyticsConventionPlugin.kt so it compiles cleanly without Firebase
        ./remove-firebase-analytics-plugin.patch
      ];

      gradleBuildTask = ":app:assembleFdroidRelease";
      gradleUpdateTask = finalAttrs.gradleBuildTask;

      # Lock refresh steps:
      # 1. If Meshtastic bumps Gradle, update `gradle.version` and `gradle.hash`.
      # 2. Build the updater:
      #    nix build --impure .#meshtastic.mitmCache.updateScript
      # 3. Copy the resulting `fetch-deps.sh`, replace its `outPath=` with
      #    `/home/dev/Documents/repo/meshtastic_deps.json`, and run it from the repo root.
      mitmCache = gradle.fetchDeps {
        inherit (finalAttrs) pname;
        pkg = finalAttrs.finalPackage;
        data = ./meshtastic_deps.json;
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
        JAVA_HOME = jdk25;
        ANDROID_HOME = "${androidSdk}/share/android-sdk";
        ANDROID_SDK_ROOT = "${androidSdk}/share/android-sdk";
        ANDROID_AAPT2_FROM_MAVEN_OVERRIDE = "${androidSdk}/share/android-sdk/build-tools/36.0.0/aapt2";
        # Provide a deterministic versionCode matching the v2.7.13 release.
        # fetchFromGitHub strips .git so GitVersionValueSource can't count commits;
        # VERSION_CODE env var takes priority over the git-based calculation
        # (see app/build.gradle.kts). Value matches FDroid 2.7.10 build (29319661).
        VERSION_CODE = "29319661";
      };

      preConfigure = ''
        export ANDROID_USER_HOME="$HOME/.android"
        mkdir -p "$ANDROID_USER_HOME"
        echo "sdk.dir=${androidSdk}/share/android-sdk" > local.properties
      '';

      gradleFlags = [
        "-Dorg.gradle.java.installations.auto-download=false"
        "-Dorg.gradle.java.installations.paths=${jdk17_headless},${jdk25}"
        "-Dandroid.aapt2FromMavenOverride=${androidSdk}/share/android-sdk/build-tools/36.0.0/aapt2"
        "-Dorg.gradle.project.android.aapt2FromMavenOverride=${androidSdk}/share/android-sdk/build-tools/36.0.0/aapt2"
      ];

      installPhase = ''
        runHook preInstall
        apk_path="$(echo app/build/outputs/apk/fdroid/release/*.apk)"
        install -Dm644 "$apk_path" "$out/meshtastic.apk"
        runHook postInstall
      '';

      meta = with lib; {
        description = "Meshtastic Android app (F-Droid flavor, unsigned)";
        homepage = "https://github.com/meshtastic/Meshtastic-Android";
        license = licenses.gpl3Only;
        platforms = platforms.unix;
      };
    });
in
mk-apk-package {
  inherit appPackage;
  mainApk = "meshtastic.apk";
  signScriptName = "sign-meshtastic";
  fdroid = {
    appId = "com.geeksville.mesh";
    metadataYml = ''
      Categories:
        - Internet
      License: GPL-3.0-only
      SourceCode: https://github.com/meshtastic/Meshtastic-Android
      IssueTracker: https://github.com/meshtastic/Meshtastic-Android/issues
      AutoName: Meshtastic
      Summary: Meshtastic mesh networking app
      Description: |-
        Meshtastic is an open-source, off-grid mesh networking application
        using LoRa radios. This is the F-Droid flavor built from source.
    '';
  };
}
