{
  mk-apk-package,
  gradle2nixBuilders,
  sources,
  lib,
  jdk21,
  jdk17,
  gradle-packages,
  stdenv,
  fetchpatch,
  apksigner,
  writableTmpDirAsHomeHook,
  androidSdkBuilder,
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

  gradle =
    (gradle-packages.mkGradle {
      version = "9.4.0";
      hash = "sha256-YOpyM1bYEmPoAC/sD8+eKw7uDAhQx6PXqwpj8szGAfM=";
      defaultJava = jdk21;
    }).wrapped;

  appPackage = gradle2nixBuilders.buildGradlePackage rec {
    pname = "appstore";
    inherit version src gradle;

    lockFile = ./gradle.lock;
    buildJdk = jdk21;

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
      jdk21
      jdk17
      apksigner
      writableTmpDirAsHomeHook
    ];

    env = {
      JAVA_HOME = if stdenv.isDarwin then "${jdk21}" else "${jdk21}/lib/openjdk";
      ANDROID_HOME = "${androidSdk}/share/android-sdk";
      ANDROID_SDK_ROOT = "${androidSdk}/share/android-sdk";
      ANDROID_AAPT2_FROM_MAVEN_OVERRIDE = "${androidSdk}/share/android-sdk/build-tools/36.1.0/aapt2";
    };

    preConfigure = ''
      export ANDROID_USER_HOME="$HOME/.android"
      mkdir -p "$ANDROID_USER_HOME"
      echo "sdk.dir=${androidSdk}/share/android-sdk" > local.properties
    '';

    gradleFlags =
      let
        postfix = if stdenv.isDarwin then "" else "/lib/openjdk";
      in
      [
        "--console=plain"
        "--dependency-verification=off"
        "-Dorg.gradle.java.home=${if stdenv.isDarwin then jdk21 else "${jdk21}/lib/openjdk"}"
        "-Dorg.gradle.java.installations.auto-download=false"
        "-Dorg.gradle.java.installations.paths=${jdk17}${postfix},${jdk21}${postfix}"
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
