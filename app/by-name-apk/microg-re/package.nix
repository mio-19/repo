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
  git,
}:
let
  appPackage =
    let
      androidSdk = androidSdkBuilder (s: [
        s.cmdline-tools-latest
        s.platform-tools
        s.platforms-android-36
        s.platforms-android-35
        s.build-tools-35-0-0
        s.build-tools-36-0-0
      ]);

      gradle =
        (gradle-packages.mkGradle {
          version = "8.14.3";
          hash = "sha256-vXEQIhNJMGCVbsIp2Ua+7lcVjb2J0OYrkbyg+ixfNTE=";
          defaultJava = jdk21;
        }).wrapped;
    in
    stdenv.mkDerivation (finalAttrs: {
      pname = "microg-re";
      version = "6.1.1";

      src = fetchFromGitHub {
        owner = "MorpheApp";
        repo = "MicroG-RE";
        rev = "ba8ec46d2e90779c52615ef09e0d80911bb128a6";
        hash = "sha256-2IO9HYWKgFTK3kLxL9+Ff67O61OmCJc1cr5uz+7otUQ=";
      };

      patches = [
        ./microg-re-disable-updater.patch
      ];

      gradleBuildTask = ":play-services-core:assembleDefaultRelease";
      gradleUpdateTask = finalAttrs.gradleBuildTask;

      mitmCache = gradle.fetchDeps {
        inherit (finalAttrs) pname;
        pkg = finalAttrs.finalPackage;
        data = ./microg-re_deps.json;
        silent = false;
        useBwrap = false;
      };

      nativeBuildInputs = [
        gradle
        jdk21
        apksigner
        writableTmpDirAsHomeHook
        git
      ];

      env = {
        JAVA_HOME = if stdenv.isDarwin then "${jdk21}" else "${jdk21}/lib/openjdk";
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
        "-xlintVitalAnalyzeRelease"
        "-Dorg.gradle.java.installations.auto-download=false"
        "-Dorg.gradle.java.installations.paths=${finalAttrs.env.JAVA_HOME}"
        "-Dandroid.aapt2FromMavenOverride=${androidSdk}/share/android-sdk/build-tools/36.0.0/aapt2"
        "-Dorg.gradle.project.android.aapt2FromMavenOverride=${androidSdk}/share/android-sdk/build-tools/36.0.0/aapt2"
      ];

      installPhase = ''
        runHook preInstall
        apk_dir="play-services-core/build/outputs/apk/default/release"
        apk_name="$(sed -n 's/.*"outputFile"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' "$apk_dir/output-metadata.json" | head -n 1)"
        test -n "$apk_name"
        apk_path="$apk_dir/$apk_name"
        test -f "$apk_path"
        install -Dm644 "$apk_path" "$out/microg-re.apk"
        runHook postInstall
      '';

      meta = with lib; {
        description = "MicroG RE app built from source (unsigned)";
        homepage = "https://github.com/MorpheApp/MicroG-RE";
        license = licenses.asl20;
        platforms = platforms.unix;
      };
    });
in
mk-apk-package {
  inherit appPackage;
  mainApk = "microg-re.apk";
  signScriptName = "sign-microg-re";
  fdroid = {
    appId = "app.revanced.android.gms";
    metadataYml = ''
      Categories:
        - System
      License: Apache-2.0
      SourceCode: https://github.com/MorpheApp/MicroG-RE
      IssueTracker: https://github.com/MorpheApp/MicroG-RE/issues
      AutoName: MicroG RE
      Summary: microG fork for patched Google apps
      Description: |-
        MicroG RE is a fork of microG GmsCore adapted for patched Google
        apps and distributed under an alternative package name.
        This package is built from source.
    '';
  };
}
