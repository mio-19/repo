{
  mk-apk-package,
  lib,
  jdk21_headless,
  gradle_8_13,
  stdenv,
  fetchFromGitHub,

  writableTmpDirAsHomeHook,
  androidSdkBuilder,
}:
let
  version = "2.0.0-nogms";

  src = fetchFromGitHub {
    owner = "ProtonLumo";
    repo = "android-lumo";
    tag = version;
    hash = "sha256-CGuLJyENtP4CQ91FHntm7lv+XEbL98OZVlwpIahLMmI=";
  };

  appPackage =
    let
      androidSdk = androidSdkBuilder (s: [
        s.cmdline-tools-latest
        s.platform-tools
        s.platforms-android-36

        s.build-tools-36-1-0
      ]);

      gradle = gradle_8_13;
    in
    stdenv.mkDerivation (finalAttrs: {
      pname = "lumo";
      inherit version src;

      patches = [ ./remove-sentry.patch ];

      # F-Droid metadata builds subdir `app` with Gradle flavors
      # `production` and `noGms`.
      gradleBuildTask = ":app:assembleProductionNoGmsRelease";
      gradleUpdateTask = finalAttrs.gradleBuildTask;

      mitmCache = gradle.fetchDeps {
        inherit (finalAttrs) pname;
        pkg = finalAttrs.finalPackage;
        data = ./lumo_deps.json;
        silent = false;
        useBwrap = false;
      };

      nativeBuildInputs = [
        gradle
        jdk21_headless

        writableTmpDirAsHomeHook
      ];

      env = {
        JAVA_HOME = jdk21_headless;
        ANDROID_HOME = "${androidSdk}/share/android-sdk";
        ANDROID_SDK_ROOT = "${androidSdk}/share/android-sdk";
        ANDROID_AAPT2_FROM_MAVEN_OVERRIDE = "${androidSdk}/share/android-sdk/build-tools/36.1.0/aapt2";
        SENTRY_DISABLE_TELEMETRY = "1";
        SENTRY_TELEMETRY_DISABLE = "1";
      };

      postPatch = ''
        substituteInPlace build.gradle.kts \
          --replace-fail 'alias(libs.plugins.sentry.android.gradle) apply false' '// alias(libs.plugins.sentry.android.gradle) apply false' || true
        substituteInPlace app/build.gradle.kts \
          --replace-fail 'alias(libs.plugins.sentry.android.gradle)' '// alias(libs.plugins.sentry.android.gradle)' || true
        substituteInPlace app/build.gradle.kts \
          --replace-fail 'signingConfig = signingConfigs.getByName("release")' \
            'signingConfig = if (isNoGms()) signingConfigs.getByName("debug") else signingConfigs.getByName("release")'
        substituteInPlace app/build.gradle.kts \
          --replace-fail 'compileSdk = 36' 'compileSdk = 36; buildToolsVersion = "36.1.0"'
        substituteInPlace vosk-model/build.gradle.kts \
          --replace-fail 'compileSdk = 36' 'compileSdk = 36; buildToolsVersion = "36.1.0"'
      '';

      preConfigure = ''
        export ANDROID_USER_HOME="$HOME/.android"
        mkdir -p "$ANDROID_USER_HOME"
        echo "sdk.dir=${androidSdk}/share/android-sdk" > local.properties
      '';

      gradleFlags = [
        "-Dorg.gradle.java.installations.auto-download=false"
        "-Dorg.gradle.java.installations.paths=${jdk21_headless}"
        "-Dandroid.builder.sdkDownload=false"
        "-Dio.sentry.telemetry.enabled=false"
        "-Dsentry.telemetry.enabled=false"
        "-Dio.sentry.auto-init=false"
        "-Dsentry.auto-init=false"
        "-Dandroid.aapt2FromMavenOverride=${androidSdk}/share/android-sdk/build-tools/36.1.0/aapt2"
        "-Dorg.gradle.project.android.aapt2FromMavenOverride=${androidSdk}/share/android-sdk/build-tools/36.1.0/aapt2"
      ];

      installPhase = ''
        runHook preInstall
        apk_dir="app/build/outputs/apk/productionNoGms/release"
        apk_name="$(sed -n 's/.*"outputFile"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' "$apk_dir/output-metadata.json" | head -n 1)"
        test -n "$apk_name"
        apk_path="$apk_dir/$apk_name"
        test -f "$apk_path"
        install -Dm644 "$apk_path" "$out/lumo.apk"
        runHook postInstall
      '';

      meta = with lib; {
        description = "Proton Lumo Android app (production noGms flavor)";
        homepage = "https://lumo.proton.me/";
        license = licenses.gpl3Only;
        platforms = platforms.unix;
      };
    });
in
mk-apk-package {
  inherit appPackage;
  mainApk = "lumo.apk";
  signScriptName = "sign-lumo";
  fdroid = {
    appId = "me.proton.android.lumo";
    metadataYml = ''
      AntiFeatures:
        NonFreeNet:
          en-US: Rely on lumo.proton.me
      Categories:
        - AI Chat
        - Internet
      License: GPL-3.0-only
      AuthorName: Proton
      WebSite: https://lumo.proton.me/
      SourceCode: https://github.com/ProtonLumo/android-lumo
      IssueTracker: https://github.com/ProtonLumo/android-lumo/issues
      Changelog: https://github.com/ProtonLumo/android-lumo/releases
      AutoName: Lumo
      Summary: Native Android client for Proton Lumo
      Description: |-
        Lumo is Proton's native Android client for its AI assistant service.
        This package builds the production noGms release APK from source, matching
        F-Droid's flavor selection for the same upstream tag.
    '';
  };
}
