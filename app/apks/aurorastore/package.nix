{
  mk-apk-package,
  overrides-fromsrc,
  gradle2nixBuilders,
  lib,
  jdk21_headless,
  gradle_9_3_1,
  fetchgit,
  apksigner,
  writableTmpDirAsHomeHook,
  androidSdkBuilder,
  overrides-update,
}:
let
  version = "4.8.1";

  src = fetchgit {
    url = "https://gitlab.com/AuroraOSS/AuroraStore.git";
    tag = version;
    hash = "sha256-qNAz3ctp5ThDP9C5ksSrk79xUmey2LKw1gG+N8D4zNg=";
  };

  androidSdk = androidSdkBuilder (s: [
    s.cmdline-tools-latest
    s.platform-tools
    s.platforms-android-36
    s.build-tools-35-0-0
    s.build-tools-36-1-0
  ]);

  gradle = gradle_9_3_1;

  appPackage = gradle2nixBuilders.buildGradlePackage rec {
    pname = "aurorastore";
    inherit version src gradle;

    lockFile = ./gradle.lock;
    overrides = overrides-fromsrc // overrides-update;
    buildJdk = jdk21_headless;

    nativeBuildInputs = [
      androidSdk
      gradle
      jdk21_headless
      apksigner
      writableTmpDirAsHomeHook
    ];

    dontUseGradleConfigure = true;

    env = {
      JAVA_HOME = jdk21_headless;
      ANDROID_HOME = "${androidSdk}/share/android-sdk";
      ANDROID_SDK_ROOT = "${androidSdk}/share/android-sdk";
      ANDROID_AAPT2_FROM_MAVEN_OVERRIDE = "${androidSdk}/share/android-sdk/build-tools/36.1.0/aapt2";
    };

    preConfigure = ''
      export ANDROID_USER_HOME="$HOME/.android"
      export GRADLE_USER_HOME="$(mktemp -d)"
      export TERM=dumb
      mkdir -p "$ANDROID_USER_HOME"
      echo "sdk.dir=${androidSdk}/share/android-sdk" > local.properties
      gradleFlagsArray+=(--no-daemon --init-script "$gradleInitScript" --offline)
    '';

    postPatch = ''
      pluginResolutionBlock=$'pluginManagement {\n    resolutionStrategy {\n        eachPlugin {\n            if (requested.id.id == "com.android.application" || requested.id.id == "com.android.library") {\n                val agpVersion = requested.version ?: "8.13.2"\n                useModule("com.android.tools.build:gradle:$agpVersion")\n            }\n        }\n    }\n'
      substituteInPlace settings.gradle.kts \
        --replace-fail "pluginManagement {" "$pluginResolutionBlock"

      substituteInPlace app/build.gradle.kts \
        --replace-fail \
          'val lastCommitHash = providers.exec {' \
          'val lastCommitHash = providers.provider { "unknown" } /* patched for nix builds: no .git metadata */ ; if (false) { providers.exec {' \
        --replace-fail \
          '}.standardOutput.asText.map { it.trim() }' \
          '}.standardOutput.asText.map { it.trim() } }'
    '';

    gradleFlags = [
      "-Dorg.gradle.java.home=${jdk21_headless.home}"
      "-Dorg.gradle.java.installations.auto-download=false"
      "-Dorg.gradle.java.installations.paths=${jdk21_headless}"
      "-Dandroid.aapt2FromMavenOverride=${androidSdk}/share/android-sdk/build-tools/36.1.0/aapt2"
      "-Dorg.gradle.project.android.aapt2FromMavenOverride=${androidSdk}/share/android-sdk/build-tools/36.1.0/aapt2"
    ];

    gradleBuildFlags = ":app:assembleVanillaRelease";

    installPhase = ''
      runHook preInstall
      apk_dir="app/build/outputs/apk/vanilla/release"
      apk_name="$(sed -n 's/.*"outputFile"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' "$apk_dir/output-metadata.json" | head -n 1)"
      test -n "$apk_name"
      apk_path="$apk_dir/$apk_name"
      test -f "$apk_path"
      install -Dm644 "$apk_path" "$out/aurorastore.apk"
      runHook postInstall
    '';

    meta = with lib; {
      description = "Aurora Store app built from source";
      homepage = "https://gitlab.com/AuroraOSS/AuroraStore";
      license = licenses.gpl3Plus;
      platforms = platforms.unix;
    };
  };
in
mk-apk-package {
  inherit appPackage;
  mainApk = "aurorastore.apk";
  signScriptName = "sign-aurorastore";
  fdroid = {
    appId = "com.aurora.store";
    metadataYml = ''
      Categories:
        - App Store & Updater
      License: GPL-3.0-or-later
      SourceCode: https://gitlab.com/AuroraOSS/AuroraStore
      IssueTracker: https://gitlab.com/AuroraOSS/AuroraStore/-/issues
      Translation: https://hosted.weblate.org/projects/aurora-store/
      Changelog: https://gitlab.com/AuroraOSS/AuroraStore/-/releases
      AutoName: Aurora Store
      Summary: Alternative client for downloading apps from Google Play
      Description: |-
        Aurora Store is an alternative client for browsing and downloading apps
        from Google Play.
        This package is built from source.
    '';
  };
}
