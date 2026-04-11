{
  mk-apk-package,
  overrides-fromsrc,
  gradle2nixBuilders,
  gradle_9_4_1,
  lib,
  jdk21_headless,
  fetchFromGitHub,
  apksigner,
  zip,
  unzip,
  writableTmpDirAsHomeHook,
  androidSdkBuilder,
  overrides-update,
}:
let
  androidSdk = androidSdkBuilder (s: [
    s.cmdline-tools-latest
    s.platform-tools
    s.platforms-android-36
    s.build-tools-35-0-0
    s.build-tools-36-0-0
  ]);

  # https://github.com/koiverse/ArchiveTune/blob/v13.1.0/gradle/wrapper/gradle-wrapper.properties
  gradle = gradle_9_4_1;

  appPackage = gradle2nixBuilders.buildGradlePackage rec {
    pname = "archivetune";
    version = "13.1.0";

    src = fetchFromGitHub {
      owner = "koiverse";
      repo = "ArchiveTune";
      tag = "v${version}";
      hash = "sha256-rA3hB/snF70Oourx9ub2gXfAkWsfsxSI7X6ZOIo+Wkk=";
    };

    inherit gradle;

    # $ nix develop /path/to/repo#apk_archivetune -c nix run github:tadfisher/gradle2nix/v2
    lockFile = ./gradle.lock;
    overrides = overrides-fromsrc // overrides-update;
    buildJdk = jdk21_headless;

    nativeBuildInputs = [
      androidSdk
      gradle
      jdk21_headless
      apksigner
      zip
      unzip
      writableTmpDirAsHomeHook
    ];

    env = {
      JAVA_HOME = jdk21_headless;
      ANDROID_HOME = "${androidSdk}/share/android-sdk";
      ANDROID_SDK_ROOT = "${androidSdk}/share/android-sdk";
      ANDROID_AAPT2_FROM_MAVEN_OVERRIDE = "${androidSdk}/share/android-sdk/build-tools/35.0.0/aapt2";
    };

    gradleFlags = [
      "-xlintVitalUniversalRelease"
      "-xlintVitalArmeabiRelease"
      "-Dorg.gradle.java.home=${jdk21_headless.home}"
      "-Dorg.gradle.java.installations.auto-download=false"
      "-Dorg.gradle.java.installations.paths=${jdk21_headless}"
      "-Dandroid.aapt2FromMavenOverride=${androidSdk}/share/android-sdk/build-tools/35.0.0/aapt2"
      "-Dorg.gradle.project.android.aapt2FromMavenOverride=${androidSdk}/share/android-sdk/build-tools/35.0.0/aapt2"
    ];

    gradleBuildFlags = ":app:assembleArm64Release";

    installPhase = ''
      runHook preInstall

      apk_path="app/build/outputs/apk/arm64/release/app-arm64-release-unsigned.apk"
      res_archive="app/build/intermediates/shrunk_resources_binary_format/arm64Release/convertShrunkResourcesToBinaryArm64Release/shrunk-resources-binary-format-arm64-release.ap_"

      if [[ ! -f "$apk_path" ]]; then
        echo "ArchiveTune APK not found at $apk_path" >&2
        exit 1
      fi

      if [[ ! -f "$res_archive" ]]; then
        echo "ArchiveTune resource archive not found at $res_archive" >&2
        exit 1
      fi

      # AGP 9 currently leaves code and packaged resources in separate artifacts here.
      # Merge the packaged resources into the original APK while preserving how AGP
      # stored native libraries in the code artifact.
      tmp_res_dir="$(mktemp -d)"
      tmp_apk_raw="$(mktemp --suffix=.apk)"
      mkdir -p "$out"
      cp "$apk_path" "$tmp_apk_raw"
      unzip -q "$res_archive" -d "$tmp_res_dir"
      (
        cd "$tmp_res_dir"
        zip -qurX9 "$tmp_apk_raw" res
        zip -qurX0 "$tmp_apk_raw" AndroidManifest.xml resources.arsc
      )

      ${androidSdk}/share/android-sdk/build-tools/35.0.0/zipalign -P 16 -f 4 \
        "$tmp_apk_raw" "$out/archivetune.apk"

      ${androidSdk}/share/android-sdk/build-tools/35.0.0/aapt dump badging "$out/archivetune.apk" >/dev/null
      runHook postInstall
    '';

    meta = with lib; {
      description = "ArchiveTune YouTube Music client for Android";
      homepage = "https://github.com/koiverse/ArchiveTune";
      license = licenses.gpl3Only;
      platforms = platforms.unix;
    };
  };
in
mk-apk-package {
  inherit appPackage;
  mainApk = "archivetune.apk";
  signScriptName = "sign-archivetune";
  fdroid = {
    appId = "moe.koiverse.archivetune";
    metadataYml = ''
      AntiFeatures:
        NonFreeNet:
          en-US: Depends on YouTube and YouTube Music.
      Categories:
        - Multimedia
      License: GPL-3.0-only
      SourceCode: https://github.com/koiverse/ArchiveTune
      IssueTracker: https://github.com/koiverse/ArchiveTune/issues
      AutoName: ArchiveTune
      Summary: Privacy-focused YouTube Music client
      Description: |-
        ArchiveTune is a YouTube Music client for Android with offline-friendly
        source packaging, modern Material 3 UI, lyrics support, and playback
        customization features.
        This package is built from source.
    '';
  };
}
