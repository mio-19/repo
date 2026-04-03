{
  mk-apk-package,
  lib,
  jdk21,
  gradle-packages,
  stdenv,
  fetchgit,
  git,
  apksigner,
  writableTmpDirAsHomeHook,
  androidSdkBuilder,
}:
let
  appPackage =
    let
      version = "4.8.1";

      androidSdk = androidSdkBuilder (s: [
        s.cmdline-tools-latest
        s.platform-tools
        s.platforms-android-36
        s.build-tools-35-0-0
        s.build-tools-36-1-0
      ]);

      gradle =
        (gradle-packages.mkGradle {
          version = "9.4.0";
          hash = "sha256-YOpyM1bYEmPoAC/sD8+eKw7uDAhQx6PXqwpj8szGAfM=";
          defaultJava = jdk21;
        }).wrapped;
    in
    stdenv.mkDerivation (finalAttrs: {
      pname = "aurorastore";
      inherit version;

      src = fetchgit {
        url = "https://gitlab.com/AuroraOSS/AuroraStore.git";
        tag = finalAttrs.version;
        hash = "sha256-qNAz3ctp5ThDP9C5ksSrk79xUmey2LKw1gG+N8D4zNg=";
      };

      gradleBuildTask = ":app:assembleVanillaRelease";
      gradleUpdateTask = finalAttrs.gradleBuildTask;

      mitmCache = gradle.fetchDeps {
        inherit (finalAttrs) pname;
        pkg = finalAttrs.finalPackage;
        data = ./aurorastore_deps.json;
        silent = false;
        useBwrap = false;
      };

      nativeBuildInputs = [
        gradle
        jdk21
        git
        apksigner
        writableTmpDirAsHomeHook
      ];

      env = {
        JAVA_HOME = jdk21;
        ANDROID_HOME = "${androidSdk}/share/android-sdk";
        ANDROID_SDK_ROOT = "${androidSdk}/share/android-sdk";
        ANDROID_AAPT2_FROM_MAVEN_OVERRIDE = "${androidSdk}/share/android-sdk/build-tools/36.1.0/aapt2";
      };

      preConfigure = ''
        export ANDROID_USER_HOME="$HOME/.android"
        mkdir -p "$ANDROID_USER_HOME"
        echo "sdk.dir=${androidSdk}/share/android-sdk" > local.properties
      '';

      postPatch = ''
        substituteInPlace app/build.gradle.kts \
          --replace-fail \
            'val lastCommitHash = providers.exec {' \
            'val lastCommitHash = providers.provider { "unknown" } /* patched for nix builds: no .git metadata */ ; if (false) { providers.exec {' \
          --replace-fail \
            '}.standardOutput.asText.map { it.trim() }' \
            '}.standardOutput.asText.map { it.trim() } }'
      '';

      gradleFlags = [
        "-Dorg.gradle.java.installations.auto-download=false"
        "-Dorg.gradle.java.installations.paths=${jdk21}"
        "-Dandroid.aapt2FromMavenOverride=${androidSdk}/share/android-sdk/build-tools/36.1.0/aapt2"
        "-Dorg.gradle.project.android.aapt2FromMavenOverride=${androidSdk}/share/android-sdk/build-tools/36.1.0/aapt2"
      ];

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
    });
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
