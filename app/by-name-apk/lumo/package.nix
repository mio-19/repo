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
    rev = "7ba846b05db2d72714a99d3de23d84ea4746a608";
    hash = "sha256-sacD8lv6D1WP4aXEVGC+CymjgD0wgEQ6zpmxTo3Tx28=";
  };

  depsFile =
    if builtins.pathExists ./lumo_deps.json then
      ./lumo_deps.json
    else
      builtins.toFile "lumo_deps.json" ''
        {
          "!comment": "Bootstrap lockfile. Regenerate with lumo.mitmCache.updateScript.",
          "!version": 1
        }
      '';

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

      gradleBuildTask = ":app:assembleProductionNoGmsRelease";
      gradleUpdateTask = finalAttrs.gradleBuildTask;

      mitmCache = gradle.fetchDeps {
        inherit (finalAttrs) pname;
        pkg = finalAttrs.finalPackage;
        data = depsFile;
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
        apk_path="$(find app/build/outputs/apk -type f -name 'lumo-v*-productionNoGms-release.apk' | head -n 1)"
        test -n "$apk_path"
        install -Dm644 "$apk_path" "$out/lumo.apk"
        runHook postInstall
      '';

      meta = with lib; {
        description = "Proton Lumo Android app (unsigned APK)";
        homepage = "https://github.com/ProtonLumo/android-lumo";
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
      Categories:
        - Internet
      License: GPL-3.0-only
      SourceCode: https://github.com/ProtonLumo/android-lumo
      IssueTracker: https://github.com/ProtonLumo/android-lumo/issues
      AutoName: Lumo
      Summary: Native Android client for Proton Lumo
      Description: |-
        Lumo is Proton's native Android client for its AI assistant service.
        This package builds the production noGms release APK from source.
    '';
  };
}
