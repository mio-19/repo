{
  mk-apk-package,
  lib,
  stdenv,
  androidSdkBuilder,
  gradle-packages,
  jdk21,
  writableTmpDirAsHomeHook,
  sources,
}:
let
  appPackage =
    let

      androidSdk = androidSdkBuilder (s: [
        s.cmdline-tools-latest
        s.platform-tools
        s.platforms-android-35
        s.build-tools-35-0-0
      ]);

      gradle =
        (gradle-packages.mkGradle {
          version = "8.10.2";
          hash = "sha256-McVXE+QCM6gwOCfOtCykikcmegrUurkXcSMSHnFSTCY=";
          defaultJava = jdk21;
        }).wrapped;
    in
    stdenv.mkDerivation (finalAttrs: {
      pname = "gallery";
      inherit (sources.google_gallery) src;
      version = sources.google_gallery.date;

      sourceRoot = "${finalAttrs.src.name}/Android/src";

      gradleBuildTask = ":app:assembleRelease";
      gradleUpdateTask = finalAttrs.gradleBuildTask;

      mitmCache = gradle.fetchDeps {
        inherit (finalAttrs) pname;
        pkg = finalAttrs.finalPackage;
        data = ./gallery_deps.json;
        silent = false;
        useBwrap = false;
      };

      nativeBuildInputs = [
        gradle
        jdk21
        writableTmpDirAsHomeHook
      ];

      env = {
        JAVA_HOME = jdk21;
        ANDROID_HOME = "${androidSdk}/share/android-sdk";
        ANDROID_SDK_ROOT = "${androidSdk}/share/android-sdk";
        ANDROID_AAPT2_FROM_MAVEN_OVERRIDE = "${androidSdk}/share/android-sdk/build-tools/35.0.0/aapt2";
      };

      preConfigure = ''
        export ANDROID_USER_HOME="$HOME/.android"
        mkdir -p "$ANDROID_USER_HOME"
        cat > local.properties <<EOF
        sdk.dir=${androidSdk}/share/android-sdk
        EOF
      '';

      postPatch = ''
        substituteInPlace app/build.gradle.kts \
          --replace-fail "REPLACE_WITH_YOUR_REDIRECT_SCHEME_IN_HUGGINGFACE_APP" "com.google.ai.edge.gallery.oauthredirect" \
          --replace-fail 'applicationId = "com.google.aiedge.gallery"' 'applicationId = "com.google.ai.edge.gallery"'
        substituteInPlace app/src/main/java/com/google/ai/edge/gallery/common/ProjectConfig.kt \
          --replace-fail "REPLACE_WITH_YOUR_CLIENT_ID_IN_HUGGINGFACE_APP" "$(echo MWYwNTA3YzAtNWRiMi00MTc5LWFhYTEtYjVmZTRjNDhmYjU5Cg== | base64 -d)" \
          --replace-fail "REPLACE_WITH_YOUR_REDIRECT_URI_IN_HUGGINGFACE_APP" "com.google.ai.edge.gallery.oauthredirect://oauth_redirect" \
      '';

      gradleFlags = [
        "-Dorg.gradle.java.installations.auto-download=false"
        "-Dorg.gradle.java.installations.paths=${jdk21}"
        "-Dandroid.aapt2FromMavenOverride=${androidSdk}/share/android-sdk/build-tools/35.0.0/aapt2"
        "-Dorg.gradle.project.android.aapt2FromMavenOverride=${androidSdk}/share/android-sdk/build-tools/35.0.0/aapt2"
      ];

      installPhase = ''
        runHook preInstall
        apk_dir="app/build/outputs/apk/release"
        apk_name="$(sed -n 's/.*"outputFile"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' "$apk_dir/output-metadata.json" | head -n 1)"
        test -n "$apk_name"
        apk_path="$apk_dir/$apk_name"
        test -f "$apk_path"
        install -Dm644 "$apk_path" "$out/gallery.apk"
        runHook postInstall
      '';

      meta = with lib; {
        description = "Google AI Edge Gallery app built from source";
        homepage = "https://github.com/google-ai-edge/gallery";
        license = licenses.asl20;
        platforms = platforms.unix;
      };
    });
in
mk-apk-package {
  inherit appPackage;
  mainApk = "gallery.apk";
  signScriptName = "sign-gallery";
  fdroid = {
    appId = "com.google.ai.edge.gallery";
    metadataYml = ''
      Categories:
        - Multimedia
        - Science & Education
      License: Apache-2.0
      SourceCode: https://github.com/google-ai-edge/gallery
      IssueTracker: https://github.com/google-ai-edge/gallery/issues
      Changelog: https://github.com/google-ai-edge/gallery/releases
      AutoName: AI Edge Gallery
      Summary: Run on-device generative AI models locally
      Description: |-
        Google AI Edge Gallery is an Android app for running and testing
        on-device generative AI models locally.

        This package is built from source.
    '';
  };
}
