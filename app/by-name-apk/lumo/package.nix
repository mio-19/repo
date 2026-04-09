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
  version = "1.2.18-nogms";

  src = fetchFromGitHub {
    owner = "ProtonLumo";
    repo = "android-lumo";
    tag = version;
    hash = "sha256-sacD8lv6D1WP4aXEVGC+CymjgD0wgEQ6zpmxTo3Tx28=";
  };

  appPackage =
    let
      androidSdk = androidSdkBuilder (s: [
        s.cmdline-tools-latest
        s.platform-tools
        s.platforms-android-36
        s.build-tools-35-0-0
        s.build-tools-36-1-0
      ]);

      gradle =
        (gradle-packages.mkGradle {
          version = "8.13";
          hash = "sha256-IPGxF2I3JUpvwgTYQ0GW+hGkz7OHVnUZxhVW6HEK7Xg=";
          defaultJava = jdk21;
        }).wrapped;
    in
    stdenv.mkDerivation (finalAttrs: {
      pname = "lumo";
      inherit version src;

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
        jdk21
        apksigner
        writableTmpDirAsHomeHook
      ];

      env = {
        JAVA_HOME = jdk21;
        ANDROID_HOME = "${androidSdk}/share/android-sdk";
        ANDROID_SDK_ROOT = "${androidSdk}/share/android-sdk";
        ANDROID_AAPT2_FROM_MAVEN_OVERRIDE = "${androidSdk}/share/android-sdk/build-tools/36.1.0/aapt2";
        SENTRY_DISABLE_TELEMETRY = "1";
      };

      postPatch = ''
        substituteInPlace app/build.gradle.kts \
          --replace-fail '            signingConfig = signingConfigs.getByName("release")' \
            '            signingConfig = if (isNoGms()) signingConfigs.getByName("debug") else signingConfigs.getByName("release")'
      '';

      preConfigure = ''
        export ANDROID_USER_HOME="$HOME/.android"
        mkdir -p "$ANDROID_USER_HOME"
        echo "sdk.dir=${androidSdk}/share/android-sdk" > local.properties
      '';

      gradleFlags = [
        "-Dorg.gradle.java.installations.auto-download=false"
        "-Dorg.gradle.java.installations.paths=${jdk21}"
        "-Dandroid.builder.sdkDownload=false"
        "-Dio.sentry.telemetry.enabled=false"
        "-Dsentry.telemetry.enabled=false"
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
