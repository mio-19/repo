{
  lib,
  jdk21,
  gradle-packages,
  stdenv,
  fetchurl,
  fetchgit,
  fetchFromGitHub,
  dockerTools,
  jdk17_headless,
  apksigner,
  writableTmpDirAsHomeHook,
  androidenv,
  fetchpatch,
}:
let
  gradle =
    (gradle-packages.mkGradle {
      version = "9.4.0";
      hash = "sha256-YOpyM1bYEmPoAC/sD8+eKw7uDAhQx6PXqwpj8szGAfM=";
      defaultJava = jdk21;
    }).wrapped;
  sources = (import ./_sources/generated.nix) {
    inherit
      fetchurl
      fetchgit
      fetchFromGitHub
      dockerTools
      ;
  };
  androidBp = fetchurl {
    url = "https://raw.githubusercontent.com/GrapheneOS/platform_external_Camera/80a4cbb19f5f6f6efb5c46deb7d5f4e1bde74a07/Android.bp";
    hash = "sha256-2xXE4FZHQ28aZYdkjYQA4eqHX+W1QqsTjVgGBk1d9EY=";
  };
  androidSdk = (androidenv.override { licenseAccepted = true; }).composeAndroidPackages {
    platformVersions = [ "36" ];
    buildToolsVersions = [ "36.1.0" ];
    includeNDK = true;
    ndkVersions = [ "29.0.14206865" ];
    includeEmulator = false;
    includeSystemImages = false;
  };
in
stdenv.mkDerivation (finalAttrs: {
  pname = "grapheneos-camera";
  version = sources.grapheneos_camera.version;
  src = sources.grapheneos_camera.src;

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

  gradleBuildTask = ":app:assembleRelease";
  gradleUpdateTask = finalAttrs.gradleBuildTask;

  # Lock refresh steps:
  # 1. If upstream bumps Gradle again, update `gradle.version` and `gradle.hash` here.
  # 2. Build the updater with:
  #    NIXPKGS_ALLOW_UNFREE=1 nix build --impure .#grapheneos-camera.mitmCache.updateScript
  # 3. Copy the resulting `fetch-deps.sh`, replace its `outPath=` with
  #    `/home/dev/Documents/repo/grapheneos_camera_deps.json`, and run it from the repo root.
  mitmCache = gradle.fetchDeps {
    inherit (finalAttrs) pname;
    pkg = finalAttrs.finalPackage;
    data = "grapheneos_camera_deps.json";
    silent = false;
    useBwrap = false;
  };

  nativeBuildInputs = [
    gradle
    jdk17_headless
    apksigner
    writableTmpDirAsHomeHook
  ];

  env = {
    JAVA_HOME = jdk17_headless;
    ANDROID_HOME = "${androidSdk.androidsdk}/libexec/android-sdk";
    ANDROID_SDK_ROOT = "${androidSdk.androidsdk}/libexec/android-sdk";
    ANDROID_NDK_ROOT = "${androidSdk.androidsdk}/libexec/android-sdk/ndk-bundle";
    ANDROID_AAPT2_FROM_MAVEN_OVERRIDE = "${androidSdk.androidsdk}/libexec/android-sdk/build-tools/36.1.0/aapt2";
  };

  gradleFlags = [
    "-xlintVitalRelease"
    "-Dandroid.aapt2FromMavenOverride=${androidSdk.androidsdk}/libexec/android-sdk/build-tools/36.1.0/aapt2"
    "-Dorg.gradle.project.android.aapt2FromMavenOverride=${androidSdk.androidsdk}/libexec/android-sdk/build-tools/36.1.0/aapt2"
  ];

  preConfigure = ''
    export ANDROID_USER_HOME="$HOME/.android"
    mkdir -p "$ANDROID_USER_HOME"
  '';

  installPhase = ''
    runHook preInstall

    mkdir -p "$out/prebuilt"
    unsigned_apk="$(echo app/build/outputs/apk/release/*-unsigned.apk)"
    signed_apk="$out/prebuilt/Camera.apk"
    keystore="$TMPDIR/grapheneos-camera-signing-key.jks"

    # We don't expect out of band upgrade so use a key generated every time.
    keytool -genkeypair \
      -keystore "$keystore" \
      -storepass android \
      -keypass android \
      -alias androiddebugkey \
      -keyalg RSA \
      -keysize 4096 \
      -validity 10000 \
      -dname "CN=GrapheneOS Camera,O=GrapheneOS,C=US"

    apksigner sign \
      --v4-signing-enabled false \
      --ks "$keystore" \
      --ks-pass pass:android \
      --key-pass pass:android \
      --ks-key-alias androiddebugkey \
      --out "$signed_apk" \
      "$unsigned_apk"

    rm -f "$signed_apk.idsig"

    apksigner verify --verbose "$signed_apk"

    cp ${androidBp} "$out/Android.bp"

    runHook postInstall
  '';

  meta = with lib; {
    description = "GrapheneOS Camera app built from source";
    homepage = "https://github.com/GrapheneOS/Camera";
    license = licenses.mit;
    sourceProvenance = with sourceTypes; [
      fromSource
      binaryBytecode
    ];
    platforms = platforms.linux;
  };
})
