{
  mk-apk-package,
  overrides-fromsrc,
  gradle2nixBuilders,
  sources,
  lib,
  jdk25_headless,
  gradle_9_4_0,
  apksigner,
  writableTmpDirAsHomeHook,
  androidSdkBuilder,
  fetchpatch,
  overrides-update,
}:
let
  androidSdk = androidSdkBuilder (s: [
    s.cmdline-tools-latest
    s.platform-tools
    s.platforms-android-36
    s.build-tools-36-1-0
  ]);

  gradle = gradle_9_4_0;

  appPackage = gradle2nixBuilders.buildGradlePackage rec {
    pname = "grapheneos-info";
    version = sources.grapheneos_info.date;
    inherit (sources.grapheneos_info)
      src
      ;
    inherit gradle;

    lockFile = ./gradle.lock;
    overrides = overrides-fromsrc // overrides-update;
    buildJdk = jdk25_headless;

    patches = [
      (fetchpatch {
        name = "added release state display to info app";
        url = "https://github.com/GrapheneOS/Info/pull/56.diff";
        hash = "sha256-qMMHV6426FHw1QCg+JfpvmjO/qUvul6T/2Le7A2YQXI=";
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
      jdk25_headless
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
      "-Dorg.gradle.java.home=${jdk25_headless.home}"
      "-Dorg.gradle.java.installations.auto-download=false"
      "-Dorg.gradle.java.installations.paths=${jdk25_headless}/lib/openjdk"
      "-Dandroid.aapt2FromMavenOverride=${androidSdk}/share/android-sdk/build-tools/36.1.0/aapt2"
      "-Dorg.gradle.project.android.aapt2FromMavenOverride=${androidSdk}/share/android-sdk/build-tools/36.1.0/aapt2"
    ];

    gradleBuildFlags = ":app:assembleRelease";

    installPhase = ''
      runHook preInstall
      apk_path="$(echo app/build/outputs/apk/release/*-unsigned.apk)"
      install -Dm644 "$apk_path" "$out/Info.apk"
      runHook postInstall
    '';

    meta = with lib; {
      description = "GrapheneOS Info app (unsigned APK)";
      homepage = "https://github.com/GrapheneOS/Info";
      license = licenses.asl20;
      platforms = platforms.unix;
    };
  };
in
mk-apk-package {
  inherit appPackage;
  mainApk = "Info.apk";
  signScriptName = "sign-grapheneos-info";
}
