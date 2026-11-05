{
  mk-apk-package,
  buildGradlePackage,
  mergeLock,
  sources,
  lib,
  jdk25_headless,
  jdk17_headless,
  jdk21_headless,
  gradle_9_7_1,
  path,
  stdenv,
  rustPlatform,
  symlinkJoin,
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
    s.platforms-android-37-0
    s.build-tools-37-0-0
  ]);

  gradle = gradle_9_7_1;

  inaCargoDeps = rustPlatform.fetchCargoVendor {
    pname = "appstore-ina";
    inherit version src;
    cargoRoot = "ina";
    hash = "sha256-wOrRh9gsYQUkeTPg9W1v/8Ok6krHP5c+wB0CEt5m56I=";
  };

  mkInaJniLib =
    {
      config,
      rustTarget,
      abi,
    }:
    let
      crossPkgs = import path {
        config.allowUnfree = true;
        localSystem = stdenv.buildPlatform.system;
        crossSystem = {
          inherit config;
          androidSdkVersion = "35";
          androidNdkVersion = "29";
          useAndroidPrebuilt = true;
          rust.rustcTarget = rustTarget;
        };
      };
    in
    crossPkgs.rustPlatform.buildRustPackage {
      pname = "appstore-ina-jni-${abi}";
      inherit version src;
      sourceRoot = "${src.name}/ina";
      cargoDeps = inaCargoDeps;
      # Match upstream's cdylib-release profile without a hyphenated profile name,
      # which the cargo build hook cannot use in CARGO_PROFILE_* variables.
      env.CARGO_PROFILE_RELEASE_PANIC = "abort";
      buildNoDefaultFeatures = true;
      buildFeatures = [
        "java-ffi"
        "patch"
      ];
      cargoBuildFlags = [
        "-p"
        "ina"
      ];
      doCheck = false;
      installPhase = ''
        runHook preInstall
        install -Dm755 target/${rustTarget}/release/libina.so "$out/${abi}/libina.so"
        runHook postInstall
      '';
    };

  inaJniLibs = symlinkJoin {
    name = "appstore-ina-jni-libs";
    paths = [
      (mkInaJniLib {
        config = "aarch64-unknown-linux-android";
        rustTarget = "aarch64-linux-android";
        abi = "arm64-v8a";
      })
      (mkInaJniLib {
        config = "x86_64-unknown-linux-android";
        rustTarget = "x86_64-linux-android";
        abi = "x86_64";
      })
    ];
  };

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
      # Build Ina's Rust JNI libraries with Nix's Android cross toolchains.
      ./skip-gradle-ina-native-build.patch
      #./0001-always-show-vanadium.patch # TODO: test
      (fetchpatch {
        name = "Do not reserve space for an icon in settings list";
        url = "https://github.com/GrapheneOS/AppStore/pull/395.patch";
        hash = "sha256-s9tNIzOb10ENMe7urrbQcE2o/q/fGmBAzgdxkEZQjd0=";
      })
    ];

    postPatch = ''
      rm -f gradle/verification-metadata.xml
    '';

    nativeBuildInputs = [
      androidSdk
      jdk25_headless
      jdk17_headless
      jdk21_headless
      writableTmpDirAsHomeHook
    ];

    env = {
      JAVA_HOME = jdk17_headless.passthru.home;
      ANDROID_HOME = "${androidSdk}/share/android-sdk";
      ANDROID_SDK_ROOT = "${androidSdk}/share/android-sdk";
      ANDROID_AAPT2_FROM_MAVEN_OVERRIDE = "${androidSdk}/share/android-sdk/build-tools/37.0.0/aapt2";
    };

    preConfigure = ''
      export ANDROID_USER_HOME="$HOME/.android"
      mkdir -p "$ANDROID_USER_HOME"
      echo "sdk.dir=${androidSdk}/share/android-sdk" > local.properties
      mkdir -p ina/android/src/main/jniLibs
      cp -r ${inaJniLibs}/. ina/android/src/main/jniLibs/
    '';

    gradleFlags = [
      "--console=plain"
      "--dependency-verification=off"
      "-Dorg.gradle.java.home=${jdk17_headless.passthru.home}"
      "-Dorg.gradle.java.installations.auto-download=false"
      "-Dorg.gradle.java.installations.paths=${jdk17_headless.passthru.home},${jdk21_headless.passthru.home},${jdk25_headless.passthru.home}"
      "-Dandroid.aapt2FromMavenOverride=${androidSdk}/share/android-sdk/build-tools/37.0.0/aapt2"
      "-Dorg.gradle.project.android.aapt2FromMavenOverride=${androidSdk}/share/android-sdk/build-tools/37.0.0/aapt2"
    ];

    gradleBuildFlags = ":app:assembleRelease";

    passthru = { inherit inaCargoDeps inaJniLibs; };

    installPhase = ''
      runHook preInstall
      apk_path="$(echo app/build/outputs/apk/release/*-release-unsigned.apk)"
      install -Dm644 "$apk_path" "$out/appstore.apk"
      runHook postInstall
    '';

    meta = with lib; {
      sourceProvenance = with sourceTypes; [ fromSource ];
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
