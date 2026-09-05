{
  mk-apk-package,
  lib,
  gradle_9_5_1,
  jdk21_headless,
  jdk17_headless,
  jdk25_headless,
  stdenv,
  fetchFromGitHub,

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
        s.platforms-android-37-0
        s.build-tools-36-0-0
      ]);

      gradle = gradle_9_5_1;
    in
    stdenv.mkDerivation (finalAttrs: {
      pname = "meshtastic";
      version = "2.8.1";

      src = fetchFromGitHub {
        owner = "meshtastic";
        repo = "Meshtastic-Android";
        rev = "v${finalAttrs.version}";
        hash = "sha256-t0z69+JTse2KOxBiMGvBQVeh9j4fHlubZkFJoRYGBWY=";
        fetchSubmodules = true;
      };

      patches = [
        ./0001-checkReleaseBuilds-false.patch
        # Remove foojay JDK auto-provisioner (prevents network access in sandbox).
        # Must be first: later patches assume this line is already gone.
        ./remove-foojay.patch
        # Remove develocity build-scan plugin (not needed for building,
        # and causes class-load errors with Gradle 9.3.1)
        # Remove desktopApp vendor requirement
        ./remove-desktopApp-vendor.patch
        # Remove firebase plugin declarations (unneeded for fdroid flavor)
        ./remove-firebase-root.patch
        ./remove-firebase-convention.patch
        # Remove firebase-crashlytics apply() and plugins.withId block from
        # AnalyticsConventionPlugin.kt so it compiles cleanly without Firebase
        ./remove-firebase-analytics-plugin.patch
      ];

      gradleBuildTask = ":androidApp:assembleFdroidRelease";
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
        useBwrap = true;
      };

      nativeBuildInputs = [
        gradle
        jdk17_headless

        writableTmpDirAsHomeHook
        git
      ];

      env = {
        JAVA_HOME = jdk25_headless.passthru.home;
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

        # gradle.fetchDeps writes invalid Maven snapshot metadata for this
        # hyphenated snapshot version. Provide a normalized local repository
        # before Gradle resolves the KMP published variants.
        cacheRoot="${finalAttrs.mitmCache}/https/central.sonatype.com/repository/maven-snapshots/org/meshtastic"
        repoRoot="offline-repository/org/meshtastic"
        for artifact in protobufs protobufs-android protobufs-jvm protobufs-iosarm64 protobufs-iossimulatorarm64; do
          srcDir="$cacheRoot/$artifact/2.7.26.151-gef0ae57-SNAPSHOT"
          dstDir="$repoRoot/$artifact/2.7.26.151-gef0ae57-SNAPSHOT"
          if [ ! -d "$srcDir" ]; then
            continue
          fi

          mkdir -p "$dstDir"
          for file in "$srcDir"/*; do
            target="$dstDir/$(basename "$file")"
            if [ ! -e "$target" ]; then
              ln -s "$(readlink -f "$file")" "$target"
            fi
          done

          metadata="$dstDir/maven-metadata.xml"
          if [ -e "$srcDir/maven-metadata.xml" ]; then
            if [ -e "$metadata" ]; then
              mv "$metadata" "$metadata.orig"
            fi
            cp "$(readlink -f "$srcDir/maven-metadata.xml")" "$metadata"
            chmod u+w "$metadata"
            substituteInPlace "$metadata" \
              --replace-fail '<timestamp>gef0ae57</timestamp>' '<timestamp>20260819.194522</timestamp>' \
              --replace-fail '<buildNumber>20260819.194522</buildNumber>' '<buildNumber>1</buildNumber>' \
              --replace-fail '<classifier>1</classifier>' "" \
              --replace-fail '<updated>gef0ae57</updated>' '<updated>20260819194522</updated>'
          fi

          for ext in module pom aar jar; do
            timestamped="$dstDir/$artifact-2.7.26.151-gef0ae57-20260819.194522-1.$ext"
            snapshot="$dstDir/$artifact-2.7.26.151-gef0ae57-SNAPSHOT.$ext"
            if [ -e "$timestamped" ] && [ ! -e "$snapshot" ]; then
              ln -s "$(basename "$timestamped")" "$snapshot"
            fi
          done
        done
      '';

      gradleFlags = [
        "-x"
        "checkFdroidReleaseAarMetadata"
        "-x"
        "checkReleaseAarMetadata"
        "-x"
        "checkDebugAarMetadata"
        "--no-configuration-cache"
        "-Dorg.gradle.java.installations.auto-download=false"
        "-Dorg.gradle.java.installations.paths=${jdk17_headless.passthru.home},${jdk21_headless.passthru.home},${jdk25_headless.passthru.home}"
        "-Dandroid.aapt2FromMavenOverride=${androidSdk}/share/android-sdk/build-tools/36.0.0/aapt2"
        "-Dorg.gradle.project.android.aapt2FromMavenOverride=${androidSdk}/share/android-sdk/build-tools/36.0.0/aapt2"
      ];

      installPhase = ''
        runHook preInstall
        apk_dir="androidApp/build/outputs/apk/fdroid/release"
        apk_path="$(find "$apk_dir" -maxdepth 1 -type f -name '*universal*.apk' | sort | head -n1)"
        if [ -z "$apk_path" ]; then
          apk_path="$(find "$apk_dir" -maxdepth 1 -type f -name '*.apk' | sort | head -n1)"
        fi
        if [ -z "$apk_path" ]; then
          echo "No APK found in $apk_dir" >&2
          find "$apk_dir" -maxdepth 1 -print >&2
          exit 1
        fi
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
