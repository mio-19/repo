{
  mk-apk-package,
  lib,
  jdk21,
  gradle-packages,
  stdenv,
  fetchFromGitHub,
  fetchurl,
  apksigner,
  writableTmpDirAsHomeHook,
  androidSdkBuilder,
}:
let
  appPackage =
    let
      androidSdk = androidSdkBuilder (s: [
        s.cmdline-tools-latest
        s.platform-tools
        s.platforms-android-36
        s.build-tools-36-0-0
      ]);

      gradle =
        (gradle-packages.mkGradle {
          version = "9.3.1";
          hash = "sha256-smbV/2uQ6tptw7IMsJDjcxMC5VOifF0+TfHw12vq/wY=";
          defaultJava = jdk21;
        }).wrapped;

      libv2rayAar = fetchurl {
        url = "https://github.com/2dust/AndroidLibXrayLite/releases/download/v26.3.27/libv2ray.aar";
        hash = "sha256-qsRd/DHoyF/OFGQa+smhdH/IiTi89LyqXeAFFHiAuqk=";
      };
    in
    stdenv.mkDerivation (finalAttrs: {
      pname = "v2rayng";
      version = "2.0.17";

      src = fetchFromGitHub {
        owner = "2dust";
        repo = "v2rayNG";
        tag = finalAttrs.version;
        fetchSubmodules = true;
        hash = "sha256-9BeGz+/j4tZ9DW46HJ3maogWeMhDEmybwfl+CKR8QvY=";
      };

      sourceRoot = "${finalAttrs.src.name}/V2rayNG";

      gradleBuildTask = ":app:assembleFdroidRelease";
      gradleUpdateTask = finalAttrs.gradleBuildTask;

      mitmCache = gradle.fetchDeps {
        inherit (finalAttrs) pname;
        pkg = finalAttrs.finalPackage;
        data = ./v2rayng_deps.json;
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
        ANDROID_AAPT2_FROM_MAVEN_OVERRIDE = "${androidSdk}/share/android-sdk/build-tools/36.0.0/aapt2";
      };

      preConfigure = ''
        export ANDROID_USER_HOME="$HOME/.android"
        mkdir -p "$ANDROID_USER_HOME"
        echo "sdk.dir=${androidSdk}/share/android-sdk" > local.properties
        mkdir -p app/libs
        cp ${libv2rayAar} app/libs/libv2ray.aar
      '';

      postPatch = ''
        pluginResolutionBlock=$'pluginManagement {\n    resolutionStrategy {\n        eachPlugin {\n            if (requested.id.id == "com.android.application" || requested.id.id == "com.android.library") {\n                val agpVersion = requested.version ?: "9.1.0"\n                useModule("com.android.tools.build:gradle:$agpVersion")\n            }\n            if (requested.id.id == "org.jetbrains.kotlin.android") {\n                val kotlinVersion = requested.version ?: "2.3.10"\n                useModule("org.jetbrains.kotlin:kotlin-gradle-plugin:$kotlinVersion")\n            }\n        }\n    }\n'
        substituteInPlace settings.gradle.kts \
          --replace-fail "pluginManagement {" "$pluginResolutionBlock"
      '';

      gradleFlags = [
        "-Dorg.gradle.java.installations.auto-download=false"
        "-Dorg.gradle.java.installations.paths=${jdk21}"
        "-Dandroid.aapt2FromMavenOverride=${androidSdk}/share/android-sdk/build-tools/36.0.0/aapt2"
        "-Dorg.gradle.project.android.aapt2FromMavenOverride=${androidSdk}/share/android-sdk/build-tools/36.0.0/aapt2"
      ];

      installPhase = ''
        runHook preInstall
        apk_path="$(find app/build/outputs/apk/fdroid/release -type f -name '*fdroid_universal.apk' | head -n1)"
        if [ -z "$apk_path" ]; then
          apk_path="$(find app/build/outputs/apk/fdroid/release -type f -name '*.apk' | head -n1)"
        fi
        test -n "$apk_path"
        install -Dm644 "$apk_path" "$out/v2rayng.apk"
        runHook postInstall
      '';

      meta = with lib; {
        description = "v2rayNG Android client built from source";
        homepage = "https://github.com/2dust/v2rayNG";
        license = licenses.gpl3Only;
        platforms = platforms.unix;
      };
    });
in
mk-apk-package {
  inherit appPackage;
  mainApk = "v2rayng.apk";
  signScriptName = "sign-v2rayng";
  fdroid = {
    appId = "com.v2ray.ang.fdroid";
    metadataYml = ''
      Categories:
        - Internet
      License: GPL-3.0-only
      SourceCode: https://github.com/2dust/v2rayNG
      IssueTracker: https://github.com/2dust/v2rayNG/issues
      Changelog: https://github.com/2dust/v2rayNG/releases
      AutoName: v2rayNG
      Summary: V2Ray/Xray client for Android
      Description: |-
        v2rayNG is an Android client for V2Ray and Xray cores.
        This package builds the upstream F-Droid flavor from source.
    '';
  };
}
