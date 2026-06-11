{
  mk-apk-package,
  overrides-fromsrc,
  overrides-fromsrc-updated,
  buildGradlePackage,
  lib,
  androidSdkBuilder,
  gradle_8_10_2,
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

  gradle = gradle_8_10_2;

  appVersionName = "1.0.16"; # kept in sync with appVersionName in upstream source code. remember to set upstreamAllowlist's hash to empty to get new hash when bumping version.
  allowlistVersion = lib.replaceStrings [ "." ] [ "_" ] appVersionName;

  upstreamAllowlist = fetchurl {
    # https://github.com/google-ai-edge/gallery/blob/ff16cf71ca75dcf83072bd69546051d10c85039f/Android/src/app/src/main/java/com/google/ai/edge/gallery/ui/modelmanager/ModelManagerViewModel.kt#L86
    # https://github.com/google-ai-edge/gallery/tree/ff16cf71ca75dcf83072bd69546051d10c85039f/model_allowlists
    #url = "https://raw.githubusercontent.com/google-ai-edge/gallery/refs/heads/main/model_allowlists/${allowlistVersion}.json";
    url = "https://raw.githubusercontent.com/google-ai-edge/gallery/refs/heads/main/model_allowlists/1_0_15.json"; # 1.0.16 not yet added
    hash = "sha256-EMNpTi4RSvr8GsjKjVBJbGeYogf8f753q5nfGoU0kPk=";
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
          "capabilities": [
            "llm_thinking"
          ],
          "capabilityToTaskTypes": {
            "llm_thinking": [
              "llm_chat"
            ]
          },
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
        },
        {
          "name": "supergemma4-e4b-abliterated",
          "modelId": "typomonster/supergemma4-e4b-abliterated-litert-lm",
          "modelFile": "supergemma4-e4b-abliterated.litertlm",
          "description": "An abliterated variant of Gemma 4 E4B (supergemma4) ready for deployment on Android using LiteRT-LM.",
          "sizeInBytes": 3654467584,
          "minDeviceMemoryInGb": 12,
          "commitHash": "3cb37a0fe1688c84cdb9faaa273052d82b8ca68b",
          "capabilities": [
            "llm_thinking"
          ],
          "capabilityToTaskTypes": {
            "llm_thinking": [
              "llm_chat"
            ]
          },
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
    overrides =
      (builtins.removeAttrs overrides-fromsrc-updated [
        "org.jetbrains.kotlinx:kotlinx-io-core-jvm:0.8.2"
        "org.jetbrains.kotlinx:kotlinx-io-bytestring-jvm:0.8.2"
        "org.jetbrains.kotlinx:kotlinx-io-core:0.8.2"
        "org.jetbrains.kotlinx:kotlinx-io-bytestring:0.8.2"
      ])
      // {
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
        --replace-fail 'applicationId = "com.google.aiedge.gallery"' 'applicationId = "com.google.ai.edge.gallery"' \
        --replace-fail 'versionName = "${appVersionName}"' 'versionName = "${appVersionName}"' # not actually replacing. this makes sure that appVersionName is kept in sync with the version in source code.
      substituteInPlace app/src/main/java/com/google/ai/edge/gallery/common/ProjectConfig.kt \
        --replace-fail "REPLACE_WITH_YOUR_CLIENT_ID_IN_HUGGINGFACE_APP" "$(echo MWYwNTA3YzAtNWRiMi00MTc5LWFhYTEtYjVmZTRjNDhmYjU5Cg== | base64 -d | tr -d '\n')" \
        --replace-fail "REPLACE_WITH_YOUR_REDIRECT_URI_IN_HUGGINGFACE_APP" "com.google.ai.edge.gallery.oauthredirect://oauth_redirect"

      patch -p0 < ${./modelmanager-use-bundled-allowlist.patch}

      install -Dm644 ${patchedAllowlist} app/src/main/assets/model_allowlist.json
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
