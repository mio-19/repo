{
  mk-apk-package,
  gradle2nix_overrides,
  gradle2nixBuilders,
  sources,
  lib,
  jdk21,
  jdk17,
  gradle-packages,
  apksigner,
  writableTmpDirAsHomeHook,
  androidSdkBuilder,
  fetchpatch,
}:
let
  inherit (sources.grapheneos_camera)
    src
    version
    ;

  androidSdk = androidSdkBuilder (s: [
    s.cmdline-tools-latest
    s.platform-tools
    s.platforms-android-36
    s.build-tools-36-1-0
  ]);

  gradle =
    (gradle-packages.mkGradle {
      version = "9.4.0";
      hash = "sha256-YOpyM1bYEmPoAC/sD8+eKw7uDAhQx6PXqwpj8szGAfM=";
      defaultJava = jdk21;
    }).wrapped;

  appPackage = gradle2nixBuilders.buildGradlePackage rec {
    pname = "grapheneos-camera";
    inherit version src gradle;

    lockFile = ./gradle.lock;
    overrides = gradle2nix_overrides;
    buildJdk = jdk21;

    patches = [
      (fetchpatch {
        name = "Add swipe haptics";
        url = "https://github.com/GrapheneOS/Camera/pull/351.patch";
        hash = "sha256-H/mU1tF/GgIMwnEpF5OKbp3u1J+cFBK8cKbB3cb7nA4=";
      })
      (fetchpatch {
        name = "Replace orientation API calls with sensor calculated orientation";
        url = "https://github.com/GrapheneOS/Camera/pull/535.patch";
        hash = "sha256-P4T5aKouSxAA0Q53vO6kJLputt3bSiPzR9EHwX8alSc=";
      })
      (fetchpatch {
        name = "Support beginning a video recording with the microphone muted";
        url = "https://github.com/GrapheneOS/Camera/pull/553.patch";
        hash = "sha256-QU/69Ugl8BQhwoYcs1izA9reRqcUi0/6sX8YzPr9yMg=";
      })
    ];

    postPatch = ''
      rm -f gradle/verification-metadata.xml

      pluginResolutionBlock=$'pluginManagement {\n    resolutionStrategy {\n        eachPlugin {\n            if (requested.id.id == "com.android.application" || requested.id.id == "com.android.library") {\n                val agpVersion = requested.version ?: "9.0.0"\n                useModule("com.android.tools.build:gradle:$agpVersion")\n            }\n        }\n    }\n'
      substituteInPlace settings.gradle.kts \
        --replace-fail "pluginManagement {" "$pluginResolutionBlock"
    '';

    nativeBuildInputs = [
      androidSdk
      gradle
      jdk21
      jdk17
      apksigner
      writableTmpDirAsHomeHook
    ];

    dontUseGradleConfigure = true;

    env = {
      ANDROID_HOME = "${androidSdk}/share/android-sdk";
      ANDROID_SDK_ROOT = "${androidSdk}/share/android-sdk";
      ANDROID_AAPT2_FROM_MAVEN_OVERRIDE = "${androidSdk}/share/android-sdk/build-tools/36.1.0/aapt2";
    };

    preConfigure = ''
      export ANDROID_USER_HOME="$HOME/.android"
      export GRADLE_USER_HOME="$(mktemp -d)"
      export TERM=dumb
      mkdir -p "$ANDROID_USER_HOME"
      echo "sdk.dir=${androidSdk}/share/android-sdk" > local.properties
      gradleFlagsArray+=(--no-daemon --init-script "$gradleInitScript" --offline)
    '';

    gradleFlags = [
      "-Dorg.gradle.java.home=${jdk21.home}"
      "-Dorg.gradle.java.installations.auto-download=false"
      "-Dorg.gradle.java.installations.paths=${jdk17}/lib/openjdk,${jdk21}/lib/openjdk"
      "-Dandroid.aapt2FromMavenOverride=${androidSdk}/share/android-sdk/build-tools/36.1.0/aapt2"
      "-Dorg.gradle.project.android.aapt2FromMavenOverride=${androidSdk}/share/android-sdk/build-tools/36.1.0/aapt2"
    ];

    gradleBuildFlags = ":app:assembleRelease";

    installPhase = ''
      runHook preInstall
      apk_path="$(echo app/build/outputs/apk/release/*-unsigned.apk)"
      install -Dm644 "$apk_path" "$out/Camera.apk"
      runHook postInstall
    '';

    meta = with lib; {
      description = "GrapheneOS Camera app (unsigned APK)";
      homepage = "https://github.com/GrapheneOS/Camera";
      license = licenses.mit;
      platforms = platforms.unix;
    };
  };
in
mk-apk-package {
  inherit appPackage;
  mainApk = "Camera.apk";
  signScriptName = "sign-grapheneos-camera";
}
