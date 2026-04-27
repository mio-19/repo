{
  mk-apk-package,
  buildGradlePackage,
  mergeLock,
  sources,
  lib,
  jdk25_headless,
  jdk17_headless,
  gradle_9_4_1,
  fetchpatch,
  writableTmpDirAsHomeHook,
  androidSdkBuilder,
  overrides-fromsrc-updated,
}:
let
  inherit (sources.grapheneos_appstore)
    src
    version
    ;

  androidSdk = androidSdkBuilder (s: [
    s.cmdline-tools-latest
    s.platform-tools
    s.platforms-android-36
    s.build-tools-36-1-0
  ]);

  gradle = gradle_9_4_1;

  appPackage = buildGradlePackage {
    pname = "appstore";
    inherit version src gradle;

    lockFile = mergeLock [
      ./gradle.lock
      ./more.gradle.lock
    ];
    overrides = overrides-fromsrc-updated;
    buildJdk = jdk17_headless;

    patches = [
      ./0001-always-show-vanadium.patch # TODO: test
      (fetchpatch {
        name = "Fix details screen shared axis transition grouping";
        url = "https://github.com/GrapheneOS/AppStore/pull/469.patch";
        hash = "sha256-/V0ZvhOLtceDjUG2JIsPWg4KgGQRzSdQe2kQ+pF7QXE=";
      })
      (fetchpatch {
        name = "Do not reserve space for an icon in settings list";
        url = "https://github.com/GrapheneOS/AppStore/pull/395.patch";
        hash = "sha256-s9tNIzOb10ENMe7urrbQcE2o/q/fGmBAzgdxkEZQjd0=";
      })
    ];

    postPatch = ''
      pluginResolutionBlock=$'pluginManagement {\n    resolutionStrategy {\n        eachPlugin {\n            if (requested.id.id == "com.android.application" || requested.id.id == "com.android.library") {\n                val agpVersion = requested.version ?: "9.0.0"\n                useModule("com.android.tools.build:gradle:$agpVersion")\n            }\n        }\n    }\n'
      substituteInPlace settings.gradle.kts \
        --replace-fail "pluginManagement {" "$pluginResolutionBlock"
    '';

    nativeBuildInputs = [
      androidSdk
      jdk25_headless
      jdk17_headless
      writableTmpDirAsHomeHook
    ];

    env = {
      JAVA_HOME = jdk17_headless.passthru.home;
      ANDROID_HOME = "${androidSdk}/share/android-sdk";
      ANDROID_SDK_ROOT = "${androidSdk}/share/android-sdk";
      ANDROID_AAPT2_FROM_MAVEN_OVERRIDE = "${androidSdk}/share/android-sdk/build-tools/36.1.0/aapt2";
    };

    preConfigure = ''
      export ANDROID_USER_HOME="$HOME/.android"
      mkdir -p "$ANDROID_USER_HOME"
      echo "sdk.dir=${androidSdk}/share/android-sdk" > local.properties
    '';

    gradleFlags = [
      "--console=plain"
      "--dependency-verification=off"
      "-Dorg.gradle.java.home=${jdk17_headless.passthru.home}"
      "-Dorg.gradle.java.installations.auto-download=false"
      "-Dorg.gradle.java.installations.paths=${jdk17_headless.passthru.home},${jdk25_headless.passthru.home}"
      "-Dandroid.aapt2FromMavenOverride=${androidSdk}/share/android-sdk/build-tools/36.1.0/aapt2"
      "-Dorg.gradle.project.android.aapt2FromMavenOverride=${androidSdk}/share/android-sdk/build-tools/36.1.0/aapt2"
    ];

    gradleBuildFlags = ":app:assembleRelease";

    installPhase = ''
      runHook preInstall
      apk_path="$(echo app/build/outputs/apk/release/*-release-unsigned.apk)"
      install -Dm644 "$apk_path" "$out/appstore.apk"
      runHook postInstall
    '';

    meta = with lib; {
      description = "GrapheneOS App Store app (unsigned APK)";
      homepage = "https://github.com/GrapheneOS/AppStore";
      license = licenses.asl20;
      platforms = platforms.unix;
    };
  };
in
mk-apk-package {
  inherit appPackage;
  mainApk = "appstore.apk";
  signScriptName = "sign-appstore";
  fdroid = {
    appId = "app.grapheneos.apps";
    metadataYml = ''
      Categories:
        - System
      License: Apache-2.0
      SourceCode: https://github.com/GrapheneOS/AppStore
      IssueTracker: https://github.com/GrapheneOS/AppStore/issues
      AutoName: GrapheneOS App Store
      Summary: App repository client for GrapheneOS apps
      Description: |-
        GrapheneOS App Store is the client for GrapheneOS app repositories.
        This package is built from source.
    '';
  };
}
