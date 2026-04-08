{
  mk-apk-package,
  overrides-from-source,
  gradle2nixBuilders,
  lib,
  jdk21,
  jdk17_headless,
  gradle-packages,
  fetchFromGitea,
  apksigner,
  writableTmpDirAsHomeHook,
  androidSdkBuilder,
  git,
}:
let
  version = "1.3.1";

  src = fetchFromGitea {
    domain = "codeberg.org";
    owner = "Sunup";
    repo = "android";
    rev = version;
    hash = "sha256-9KoM8a8sMvN0zNv5gXPZDOjv1U+oI5WA/w2Ilcdn/mI=";
  };

  androidSdk = androidSdkBuilder (s: [
    s.cmdline-tools-latest
    s.platform-tools
    s.platforms-android-36
    s.build-tools-35-0-0
  ]);

  gradle =
    (gradle-packages.mkGradle {
      version = "8.13";
      hash = "sha256-IPGxF2I3JUpvwgTYQ0GW+hGkz7OHVnUZxhVW6HEK7Xg=";
      defaultJava = jdk21;
    }).wrapped;

  appPackage = gradle2nixBuilders.buildGradlePackage rec {
    pname = "sunup";
    inherit version src gradle;

    lockFile = ./gradle.lock;
    overrides = overrides-from-source;
    buildJdk = jdk17_headless;

    postPatch = ''
      pluginResolutionBlock=$'pluginManagement {\n    resolutionStrategy {\n        eachPlugin {\n            if (requested.id.id == "com.android.application" || requested.id.id == "com.android.library") {\n                val agpVersion = requested.version ?: "8.13.2"\n                useModule("com.android.tools.build:gradle:$agpVersion")\n            }\n        }\n    }\n'
      substituteInPlace settings.gradle.kts \
        --replace-fail "pluginManagement {" "$pluginResolutionBlock"
    '';

    nativeBuildInputs = [
      androidSdk
      gradle
      jdk17_headless
      apksigner
      writableTmpDirAsHomeHook
      git
    ];

    dontUseGradleConfigure = true;

    env = {
      JAVA_HOME = jdk17_headless;
      ANDROID_HOME = "${androidSdk}/share/android-sdk";
      ANDROID_SDK_ROOT = "${androidSdk}/share/android-sdk";
      ANDROID_AAPT2_FROM_MAVEN_OVERRIDE = "${androidSdk}/share/android-sdk/build-tools/35.0.0/aapt2";
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
      "-x"
      "lintVitalRelease"
      "-Dorg.gradle.java.home=${jdk17_headless.home}"
      "-Dorg.gradle.java.installations.auto-download=false"
      "-Dorg.gradle.java.installations.paths=${jdk17_headless},${jdk21}"
      "-Dandroid.aapt2FromMavenOverride=${androidSdk}/share/android-sdk/build-tools/35.0.0/aapt2"
      "-Dorg.gradle.project.android.aapt2FromMavenOverride=${androidSdk}/share/android-sdk/build-tools/35.0.0/aapt2"
    ];

    gradleBuildFlags = ":app:assembleRelease";

    installPhase = ''
      runHook preInstall
      apk_path="$(echo app/build/outputs/apk/release/*.apk)"
      install -Dm644 "$apk_path" "$out/sunup.apk"
      runHook postInstall
    '';

    meta = with lib; {
      description = "UnifiedPush distributor using a local push gateway";
      homepage = "https://codeberg.org/Sunup/android";
      license = licenses.gpl3Plus;
      platforms = platforms.unix;
    };
  };
in
mk-apk-package {
  inherit appPackage;
  mainApk = "sunup.apk";
  signScriptName = "sign-sunup";
  fdroid = {
    appId = "org.unifiedpush.distributor.sunup";
    metadataYml = ''
      Categories:
        - System
      License: GPL-3.0-or-later
      SourceCode: https://codeberg.org/Sunup/android
      IssueTracker: https://codeberg.org/Sunup/android/issues
      AutoName: Sunup
      Summary: UnifiedPush distributor using a local push gateway
      Description: |-
        Sunup is a UnifiedPush distributor that uses a local push gateway
        to deliver push notifications without relying on Google services.
        This package is built from source.
    '';
  };
}
