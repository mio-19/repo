{
  mk-apk-package,
  lib,
  jdk21_headless,
  gradle_8_9,
  stdenv,
  fetchFromGitHub,
  writableTmpDirAsHomeHook,
  androidSdkBuilder,
}:
let
  appPackage =
    let
      androidSdk = androidSdkBuilder (s: [
        s.cmdline-tools-latest
        s.platform-tools
        s.platforms-android-35
        s.platforms-android-36
        s.build-tools-34-0-0
        s.build-tools-35-0-0
        s.build-tools-36-0-0
      ]);

      gradle = gradle_8_9;
    in
    stdenv.mkDerivation (finalAttrs: {
      pname = "termux-api";
      version = "0.53.0";

      src = fetchFromGitHub {
        owner = "termux";
        repo = "termux-api";
        tag = "v${finalAttrs.version}";
        hash = "sha256-jWAGXhS8nvCEoafEfNeYSmN/R5fo7sBYAGH+Fv1LaU0=";
      };

      postPatch = ''
        substituteInPlace app/build.gradle \
          --replace-fail \
            'implementation "com.termux.termux-app:termux-shared:7bceab88e2"' \
            'implementation "com.termux.termux-app:termux-shared:7bceab88e2272f961d1b94ef736f1a9e20173247"'
      '';

      gradleBuildTask = ":app:assembleRelease";
      gradleUpdateTask = finalAttrs.gradleBuildTask;

      mitmCache = gradle.fetchDeps {
        inherit (finalAttrs) pname;
        pkg = finalAttrs.finalPackage;
        data = ./termux-api_deps.json;
        silent = false;
        useBwrap = false;
      };

      nativeBuildInputs = [
        gradle
        jdk21_headless
        writableTmpDirAsHomeHook
      ];

      env = {
        JAVA_HOME = jdk21_headless.passthru.home;
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
        "-xlintVitalRelease"
        "-Dandroid.builder.sdkDownload=false"
        "-Dorg.gradle.java.installations.auto-download=false"
        "-Dorg.gradle.java.installations.paths=${jdk21_headless.passthru.home}"
        "-Dandroid.aapt2FromMavenOverride=${androidSdk}/share/android-sdk/build-tools/36.0.0/aapt2"
        "-Dorg.gradle.project.android.aapt2FromMavenOverride=${androidSdk}/share/android-sdk/build-tools/36.0.0/aapt2"
      ];

      installPhase = ''
        runHook preInstall
        apk_dir="app/build/outputs/apk/release"
        apk_name="$(sed -n 's/.*"outputFile"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' "$apk_dir/output-metadata.json" | head -n 1)"
        if [[ -z "$apk_name" || ! -f "$apk_dir/$apk_name" ]]; then
          apk_path="$(find "$apk_dir" -name "*.apk" | head -n 1)"
        else
          apk_path="$apk_dir/$apk_name"
        fi
        test -f "$apk_path"
        install -Dm644 "$apk_path" "$out/termux-api.apk"
        runHook postInstall
      '';

      meta = with lib; {
        sourceProvenance = with sourceTypes; [ fromSource ];
        description = "Termux add-on app exposing Android API to command line";
        homepage = "https://github.com/termux/termux-api";
        license = licenses.gpl3Only;
        platforms = platforms.unix;
      };
    });
in
mk-apk-package {
  inherit appPackage;
  mainApk = "termux-api.apk";
  signScriptName = "sign-termux-api";
  fdroid = {
    appId = "com.termux.api";
    metadataYml = ''
      Categories:
        - Development
      License: GPL-3.0-only
      WebSite: https://termux.com
      SourceCode: https://github.com/termux/termux-api
      IssueTracker: https://github.com/termux/termux-api/issues
      Changelog: https://github.com/termux/termux-api/releases
      Donate: https://termux.com/donate.html
      OpenCollective: Termux
      AutoName: Termux:API
      Summary: Termux add-on exposing Android API to command line
      Description: |-
        Termux:API is an add-on app for Termux that exposes Android device
        features and APIs (such as battery, camera, location, notifications,
        sensors, SMS, and clipboard) to command-line scripts.
    '';
  };
}
