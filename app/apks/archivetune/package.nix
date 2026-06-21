{
  agp-resolution,
  mk-apk-package,
  overrides-fromsrc,
  gradle_9_4_1,
  lib,
  stdenv,
  jdk21_headless,
  fetchFromGitHub,
  zip,
  unzip,
  writableTmpDirAsHomeHook,
  androidSdkBuilder,
  overrides-fromsrc-updated,
  writeShellScript,
  _experimental-update-script-combinators,
  nix-update-script,
}:
let
  androidSdk = androidSdkBuilder (s: [
    s.cmdline-tools-latest
    s.platform-tools
    s.platforms-android-37-0
    # needed for AGP 9.x
    s.build-tools-36-0-0
    s.build-tools-37-0-0
    s.ndk-28-2-13676358
    s.cmake-3-22-1
  ]);

  # https://github.com/koiverse/ArchiveTune/blob/v13.4.0/gradle/wrapper/gradle-wrapper.properties
  gradle = gradle_9_4_1;

  appPackage = stdenv.mkDerivation (finalAttrs: {
    pname = "archivetune";
    version = "13.5.0";

    src = fetchFromGitHub {
      owner = "koiverse";
      repo = "ArchiveTune";
      tag = "v${finalAttrs.version}";
      fetchSubmodules = true;
      hash = "sha256-oIx5soqkGmR7OQkcHdlRS/jliQJljAZQArnnmY4MkF0=";
    };

    patches = [
      ./remove-star-dialog.patch
    ];

    gradleBuildTask = ":app:assembleFossMobileArm64Release";
    gradleUpdateTask = ":app:assembleFossMobileArm64Release";
    gradleBuildFlags = [ ":app:assembleFossMobileArm64Release" ];

    mitmCache = gradle.fetchDeps {
      inherit (finalAttrs) pname;
      attrPath = "apk_archivetune";
      pkg = finalAttrs.finalPackage.overrideAttrs (old: {
        preConfigure = ''
          export ANDROID_USER_HOME="$HOME/.android"
          mkdir -p "$ANDROID_USER_HOME"
          echo "sdk.dir=${androidSdk}/share/android-sdk" > local.properties
        '';
      });
      data = ./archivetune_deps.json;
      silent = false;
      useBwrap = false;
    };

    passthru.updateScript = _experimental-update-script-combinators.sequence [
      (nix-update-script { })
      {
        command = [
          "${writeShellScript "update-apk-archivetune-gradle-deps" ''
            set -euo pipefail
            system="$(nix eval --impure --raw --expr builtins.currentSystem)"
            "$(nix build ".#legacyPackages.$system.apk_archivetune.mitmCache.updateScript" --no-link --print-out-paths)"
          ''}"
        ];
        supportedFeatures = [ ];
      }
    ];

    nativeBuildInputs = [
      androidSdk
      gradle
      jdk21_headless
      zip
      unzip
      writableTmpDirAsHomeHook
    ];

    env = {
      JAVA_HOME = jdk21_headless;
      ANDROID_HOME = "${androidSdk}/share/android-sdk";
      ANDROID_SDK_ROOT = "${androidSdk}/share/android-sdk";
      ANDROID_NDK_HOME = "${androidSdk}/share/android-sdk/ndk/28.2.13676358";
      ANDROID_AAPT2_FROM_MAVEN_OVERRIDE = "${androidSdk}/share/android-sdk/build-tools/36.0.0/aapt2";
    };

    prePatch = (
      agp-resolution.patchSettingsGradle {
        file = "settings.gradle.kts";
        agpVersion = "9.2.1";
        pluginIds = [
          "com.android.application"
          "com.android.library"
        ];
      }
    );

    preConfigure = ''
      export ANDROID_USER_HOME="$HOME/.android"
      mkdir -p "$ANDROID_USER_HOME"
      echo "sdk.dir=${androidSdk}/share/android-sdk" > local.properties

      # Inject mitmCache into settings.gradle.kts pluginManagement to fix Gradle 9 offline plugin resolution
      # Only do this if finalAttrs.mitmCache actually evaluates to a path
      substituteInPlace settings.gradle.kts \
        --replace-fail "gradlePluginPortal()" "gradlePluginPortal(); maven { setUrl(uri(\"${finalAttrs.mitmCache}\")) }"
    '';

    gradleFlags = [
      "--no-configuration-cache"
      "-xlintVitalFossMobileArm64Release"
      "-Dorg.gradle.java.home=${jdk21_headless.home}"
      "-Dorg.gradle.java.installations.auto-download=false"
      "-Dorg.gradle.java.installations.paths=${jdk21_headless}"
      "-Dandroid.aapt2FromMavenOverride=${androidSdk}/share/android-sdk/build-tools/36.0.0/aapt2"
      "-Dorg.gradle.project.android.aapt2FromMavenOverride=${androidSdk}/share/android-sdk/build-tools/36.0.0/aapt2"
    ];

    installPhase = ''
      runHook preInstall

      mkdir $out
      apk_path="$(find app/build/outputs/apk -type f -name '*mobile*arm64*release*unsigned.apk' -print -quit)"
      if [ -z "$apk_path" ]; then
        echo "Could not find mobile arm64 release APK" >&2
        exit 1
      fi
      mv "$apk_path" "$out/archivetune.apk"

      runHook postInstall
    '';

    meta = with lib; {
      description = "ArchiveTune YouTube Music client for Android";
      homepage = "https://github.com/koiverse/ArchiveTune";
      license = licenses.gpl3Only;
      platforms = platforms.unix;
    };
  });
in
mk-apk-package {
  inherit appPackage;
  mainApk = "archivetune.apk";
  signScriptName = "sign-archivetune";
  fdroid = {
    appId = "moe.rukamori.archivetune";
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
