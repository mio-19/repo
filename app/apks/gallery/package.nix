{
  mk-apk-package,
  overrides-fromsrc,
  buildGradlePackage,
  lib,
  androidSdkBuilder,
  gradle-packages,
  jdk21_headless,
  runCommand,
  fetchurl,
  jq,
  writableTmpDirAsHomeHook,
  sources,
}:
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
      defaultJava = jdk21_headless;
    }).wrapped;

  upstreamAllowlist = fetchurl {
    url = "https://raw.githubusercontent.com/google-ai-edge/gallery/refs/heads/main/model_allowlists/1_0_11.json";
    hash = "sha256-jY0Vcws3j3eQK9mzUemFI06KAf98PCalK/bHA+4Us5s=";
  };

  patchedAllowlist = runCommand "gallery-model-allowlist.json" { nativeBuildInputs = [ jq ]; } ''
    jq '
      .models += [
        {
          "name": "Gemma-4-E2B-it-abliterated",
          "modelId": "nqd145/Gemma-4-E2B-it-abliterated-litertlm",
          "modelFile": "Gemma-4-E2B-it-abliterated.litertlm",
          "description": "An abliterated variant of Gemma 4 E2B ready for deployment on Android using LiteRT-LM. It is based on the official Gemma 4 E2B model.",
          "sizeInBytes": 5065244672,
          "minDeviceMemoryInGb": 8,
          "commitHash": "7c778c0c415a10ad518cf6f2ac21931610e0d223",
          "llmSupportThinking": true,
          "defaultConfig": {
            "topK": 64,
            "topP": 0.95,
            "temperature": 1.0,
            "maxContextLength": 32000,
            "maxTokens": 4000,
            "accelerators": "gpu,cpu"
          },
          "taskTypes": [
            "llm_chat",
            "llm_prompt_lab",
            "llm_agent_chat"
          ]
        }
      ]
    ' ${upstreamAllowlist} > "$out"
  '';

  appPackage = buildGradlePackage rec {
    pname = "gallery";
    inherit gradle;
    inherit (sources.google_gallery) src;
    version = sources.google_gallery.date;

    sourceRoot = "${src.name}/Android/src";

    lockFile = ./gradle.lock;
    overrides = overrides-fromsrc // {
      "com.google.protobuf:protoc:4.26.1"."protoc-4.26.1-linux-x86_64.exe" =
        src:
        runCommand "protoc-4.26.1-linux-x86_64.exe" { } ''
          cp ${src} $out
          chmod +x $out
        '';
    };
    buildJdk = jdk21_headless;

    nativeBuildInputs = [
      gradle
      jdk21_headless
      jq
      writableTmpDirAsHomeHook
    ];

    dontUseGradleConfigure = true;

    env = {
      JAVA_HOME = jdk21_headless;
      ANDROID_HOME = "${androidSdk}/share/android-sdk";
      ANDROID_SDK_ROOT = "${androidSdk}/share/android-sdk";
      ANDROID_AAPT2_FROM_MAVEN_OVERRIDE = "${androidSdk}/share/android-sdk/build-tools/35.0.0/aapt2";
    };

    preConfigure = ''
      export ANDROID_USER_HOME="$HOME/.android"
      export GRADLE_USER_HOME="$HOME/.gradle"
      export TERM=dumb
      mkdir -p "$ANDROID_USER_HOME"
      cat > local.properties <<EOF
      sdk.dir=${androidSdk}/share/android-sdk
      EOF
      gradleFlagsArray+=(--no-daemon --init-script "$gradleInitScript" --offline)
    '';

    postPatch = ''
      substituteInPlace app/build.gradle.kts \
        --replace-fail "REPLACE_WITH_YOUR_REDIRECT_SCHEME_IN_HUGGINGFACE_APP" "com.google.ai.edge.gallery.oauthredirect" \
        --replace-fail 'applicationId = "com.google.aiedge.gallery"' 'applicationId = "com.google.ai.edge.gallery"'
      substituteInPlace app/src/main/java/com/google/ai/edge/gallery/common/ProjectConfig.kt \
        --replace-fail "REPLACE_WITH_YOUR_CLIENT_ID_IN_HUGGINGFACE_APP" "$(echo MWYwNTA3YzAtNWRiMi00MTc5LWFhYTEtYjVmZTRjNDhmYjU5Cg== | base64 -d | tr -d '\n')" \
        --replace-fail "REPLACE_WITH_YOUR_REDIRECT_URI_IN_HUGGINGFACE_APP" "com.google.ai.edge.gallery.oauthredirect://oauth_redirect"

      install -Dm644 ${patchedAllowlist} app/src/main/assets/model_allowlist.json

      substituteInPlace app/src/main/java/com/google/ai/edge/gallery/ui/modelmanager/ModelManagerViewModel.kt \
        --replace-fail 'import java.io.File' $'import java.io.File\nimport java.io.InputStreamReader' \
        --replace-fail '        if (modelAllowlist == null) {' $'        if (modelAllowlist == null) {\n          try {\n            Log.d(TAG, "Loading bundled model allowlist from assets.")\n            context.assets.open(MODEL_ALLOWLIST_FILENAME).use { input ->\n              InputStreamReader(input).use { reader ->\n                modelAllowlist = Gson().fromJson(reader, ModelAllowlist::class.java)\n              }\n            }\n          } catch (e: Exception) {\n            Log.w(TAG, "Failed to load bundled model allowlist from assets", e)\n          }\n        }\n\n        if (modelAllowlist == null) {' \
        --replace-fail '        Log.d(TAG, "Allowlist: $modelAllowlist")' $'        val resolvedModelAllowlist = modelAllowlist!!\n\n        Log.d(TAG, "Allowlist: $resolvedModelAllowlist")' \
        --replace-fail '            modelAllowlist.aicoreRequirements' '            resolvedModelAllowlist.aicoreRequirements' \
        --replace-fail '        for (allowedModel in modelAllowlist.models) {' '        for (allowedModel in resolvedModelAllowlist.models) {' \
    '';

    gradleFlags = [
      "-Dorg.gradle.java.home=${jdk21_headless.home}"
      "-Dorg.gradle.java.installations.auto-download=false"
      "-Dorg.gradle.java.installations.paths=${jdk21_headless}"
      "-Dandroid.aapt2FromMavenOverride=${androidSdk}/share/android-sdk/build-tools/35.0.0/aapt2"
      "-Dorg.gradle.project.android.aapt2FromMavenOverride=${androidSdk}/share/android-sdk/build-tools/35.0.0/aapt2"
    ];

    gradleBuildFlags = ":app:assembleRelease";

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
  };
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
