{
  mk-apk-package,
  overrides-fromsrc,
  buildGradlePackage,
  lib,
  jdk25_headless,
  gradle_9_4_1,
  fetchFromGitHub,

  writableTmpDirAsHomeHook,
  androidSdkBuilder,
}:
let
  androidSdk = androidSdkBuilder (s: [
    s.cmdline-tools-latest
    s.platform-tools
    s.platforms-android-36
    s.build-tools-35-0-0
    s.build-tools-36-0-0
  ]);

  gradle = gradle_9_4_1;

  appPackage = buildGradlePackage rec {
    pname = "nextcloud-android";
    # Go to https://github.com/nextcloud/android/releases/latest to see latest release.
    version = "33.0.1";
    inherit gradle;

    src = fetchFromGitHub {
      owner = "nextcloud";
      repo = "android";
      tag = "stable-${version}";
      hash = "sha256-NAWeYEHIGMxoOpF6t/VhTRxjX1n2RTJ2AjZ8v8z3+2g=";
    };

    lockFile = ./gradle.lock;
    overrides = overrides-fromsrc;
    buildJdk = jdk25_headless;

    postPatch = ''
      rm -f gradle/verification-metadata.xml
    '';

    nativeBuildInputs = [
      androidSdk
      gradle
      jdk25_headless

      writableTmpDirAsHomeHook
    ];

    dontUseGradleConfigure = true;

    env = {
      JAVA_HOME = jdk25_headless;
      ANDROID_HOME = "${androidSdk}/share/android-sdk";
      ANDROID_SDK_ROOT = "${androidSdk}/share/android-sdk";
      ANDROID_AAPT2_FROM_MAVEN_OVERRIDE = "${androidSdk}/share/android-sdk/build-tools/36.0.0/aapt2";
    };

    preConfigure = ''
      export ANDROID_USER_HOME="$HOME/.android"
      export GRADLE_USER_HOME="$HOME/.gradle"
      export TERM=dumb
      mkdir -p "$ANDROID_USER_HOME"
      echo "sdk.dir=${androidSdk}/share/android-sdk" > local.properties
      gradleFlagsArray+=(--no-daemon --init-script "$gradleInitScript" --offline)
    '';

    gradleFlags = [
      "-Dorg.gradle.java.home=${jdk25_headless.home}"
      "-Dorg.gradle.java.installations.auto-download=false"
      "-Dorg.gradle.java.installations.paths=${jdk25_headless}"
      "-Dandroid.aapt2FromMavenOverride=${androidSdk}/share/android-sdk/build-tools/36.0.0/aapt2"
      "-Dorg.gradle.project.android.aapt2FromMavenOverride=${androidSdk}/share/android-sdk/build-tools/36.0.0/aapt2"
    ];

    gradleBuildFlags = ":app:assembleGenericRelease";

    installPhase = ''
      runHook preInstall

      apk_dir="app/build/outputs/apk/generic/release"
      apk_name="$(sed -n 's/.*"outputFile"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' "$apk_dir/output-metadata.json" | head -n 1)"
      test -n "$apk_name"
      apk_path="$apk_dir/$apk_name"
      test -f "$apk_path"
      badging="$("${androidSdk}/share/android-sdk/build-tools/36.0.0/aapt" dump badging "$apk_path")"
      pkg="$(echo "$badging" | sed -n "s/^package: name='\([^']*\)'.*/\1/p")"
      [ "$pkg" = "com.nextcloud.client" ]

      install -Dm644 "$apk_path" "$out/nextcloud-android.apk"
      runHook postInstall
    '';

    meta = with lib; {
      description = "Nextcloud Android app built from source";
      homepage = "https://github.com/nextcloud/android";
      license = licenses.agpl3Plus;
      platforms = platforms.unix;
    };
  };
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
