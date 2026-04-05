{
  mk-apk-package,
  lib,
  jdk21,
  gradle-packages,
  stdenv,
  fetchFromGitHub,
  apksigner,
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
        s.build-tools-35-0-0
        s.build-tools-36-0-0
      ]);

      gradle =
        (gradle-packages.mkGradle {
          version = "9.4.1";
          hash = "sha256-KrKVjyoeURIMMmytbzhRU7sR7pOzwhbF/M6/37t+xss=";
          defaultJava = jdk21;
        }).wrapped;
    in
    stdenv.mkDerivation (finalAttrs: {
      pname = "nextcloud-android";
      version = "33.0.1";

      src = fetchFromGitHub {
        owner = "nextcloud";
        repo = "android";
        tag = "stable-${finalAttrs.version}";
        hash = "sha256-NAWeYEHIGMxoOpF6t/VhTRxjX1n2RTJ2AjZ8v8z3+2g=";
      };

      gradleBuildTask = ":app:assembleGenericRelease";
      gradleUpdateTask = finalAttrs.gradleBuildTask;

      mitmCache = gradle.fetchDeps {
        inherit (finalAttrs) pname;
        pkg = finalAttrs.finalPackage;
        data = ./nextcloud_android_deps.json;
        silent = false;
        useBwrap = false;
      };

      nativeBuildInputs = [
        gradle
        jdk21
        apksigner
        writableTmpDirAsHomeHook
      ];

      env = {
        JAVA_HOME = jdk21;
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
        "-Dorg.gradle.java.installations.auto-download=false"
        "-Dorg.gradle.java.installations.paths=${jdk21}"
        "-Dandroid.aapt2FromMavenOverride=${androidSdk}/share/android-sdk/build-tools/36.0.0/aapt2"
        "-Dorg.gradle.project.android.aapt2FromMavenOverride=${androidSdk}/share/android-sdk/build-tools/36.0.0/aapt2"
      ];

      installPhase = ''
        runHook preInstall

        apk_path=""
        while IFS= read -r candidate; do
          [ -f "$candidate" ] || continue
          badging="$("${androidSdk}/share/android-sdk/build-tools/36.0.0/aapt" dump badging "$candidate" 2>/dev/null || true)"
          pkg="$(echo "$badging" | sed -n "s/^package: name='\([^']*\)'.*/\1/p")"
          if [ "$pkg" = "com.nextcloud.client" ]; then
            apk_path="$candidate"
            break
          fi
        done < <(find app/build -type f -name '*.apk' | sort)

        if [ -z "$apk_path" ]; then
          echo "No parseable com.nextcloud.client APK found under app/build" >&2
          find app/build -type f -name '*.apk' | sort >&2 || true
          exit 1
        fi

        install -Dm644 "$apk_path" "$out/nextcloud-android.apk"
        runHook postInstall
      '';

      meta = with lib; {
        description = "Nextcloud Android app built from source";
        homepage = "https://github.com/nextcloud/android";
        license = licenses.agpl3Plus;
        platforms = platforms.unix;
      };
    });
in
mk-apk-package {
  inherit appPackage;
  mainApk = "nextcloud-android.apk";
  signScriptName = "sign-nextcloud-android";
  fdroid = {
    appId = "com.nextcloud.client";
    metadataYml = ''
      Categories:
        - Cloud Storage & File Sync
      License: AGPL-3.0-or-later
      WebSite: https://nextcloud.com/
      SourceCode: https://github.com/nextcloud/android
      IssueTracker: https://github.com/nextcloud/android/issues
      Changelog: https://github.com/nextcloud/android/releases
      AutoName: Nextcloud
      Summary: Access and sync your Nextcloud files
      Description: |-
        Nextcloud lets you browse, upload, and synchronize files with your
        Nextcloud server from Android.

        This package is built from source from the upstream nextcloud/android
        repository using the generic (F-Droid compatible) flavor.
    '';
  };
}
