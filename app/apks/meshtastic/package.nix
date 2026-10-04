{
  mk-apk-package,
  lib,
  gradle_9_6_1,
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

      gradle = gradle_9_6_1;
    in
    stdenv.mkDerivation (finalAttrs: {
      pname = "meshtastic";
      version = "2.8.2";

      src = fetchFromGitHub {
        owner = "meshtastic";
        repo = "Meshtastic-Android";
        tag = "v${finalAttrs.version}";
        hash = "sha256-kkPm+lkGKxvJw5XrEY+HpTquyT0sK6hhdp0SnjEXcT8=";
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
                
                # Helper to patch metadata
                patch_snapshot() {
                  local artifact=$1
                  local version=$2
                  local timestamp=$3
                  local buildnumber=$4
                  
                  local srcDir="$cacheRoot/$artifact/$version-SNAPSHOT"
                  local dstDir="$repoRoot/$artifact/$version-SNAPSHOT"
                  if [ ! -d "$srcDir" ]; then return; fi
                  
                  mkdir -p "$dstDir"
                  for file in "$srcDir"/*; do
                    target="$dstDir/$(basename "$file")"
                    if [ ! -e "$target" ]; then
                      ln -s "$(readlink -f "$file")" "$target"
                    fi
                  done

                  metadata="$dstDir/maven-metadata.xml"
                  if [ -e "$srcDir/maven-metadata.xml" ]; then
                    if [ -e "$metadata" ]; then mv "$metadata" "$metadata.orig"; fi
                    # Just create a valid maven-metadata.xml for offline resolution
                    cat > "$metadata" <<EOF
        <?xml version="1.0" encoding="UTF-8"?>
        <metadata modelVersion="1.1.0">
          <groupId>org.meshtastic</groupId>
          <artifactId>$artifact</artifactId>
          <version>$version-SNAPSHOT</version>
          <versioning>
            <snapshot>
              <timestamp>$timestamp</timestamp>
              <buildNumber>$buildnumber</buildNumber>
            </snapshot>
            <lastUpdated>20260925152242</lastUpdated>
          </versioning>
        </metadata>
        EOF
                  fi

                  for ext in module pom pom.asc aar jar jar.asc; do
                    timestamped="$dstDir/$artifact-$version-$timestamp-$buildnumber.$ext"
                    snapshot="$dstDir/$artifact-$version-SNAPSHOT.$ext"
                    # Some files might have different timestamp formats depending on if they are published, but if the timestamped file exists in the cache:
                    if [ -e "$timestamped" ] && [ ! -e "$snapshot" ]; then
                      ln -s "$(basename "$timestamped")" "$snapshot"
                    fi
                  done
                }

                for artifact in protobufs protobufs-android protobufs-jvm protobufs-iosarm64 protobufs-iossimulatorarm64; do
                  patch_snapshot "$artifact" "2.8.0.117-gad0bf31" "20260925.152242" "1"
                done
                
                patch_snapshot "takpacket-sdk" "0.9.2" "20260918.000251" "6"
                for artifact in takpacket-sdk-android takpacket-sdk-jvm takpacket-sdk-iosarm64 takpacket-sdk-iossimulatorarm64; do
                  patch_snapshot "$artifact" "0.9.2" "20260918.000251" "6"
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
        sourceProvenance = with sourceTypes; [ fromSource ];
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
