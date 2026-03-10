{
  lib,
  stdenv,
  fetchurl,
  fetchgit,
  fetchFromGitHub,
  dockerTools,
  gradle_9,
  jdk17_headless,
  apksigner,
  writableTmpDirAsHomeHook,
  androidenv,
  fetchpatch,
}:
let
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

  mitmCache = gradle_9.fetchDeps {
    inherit (finalAttrs) pname;
    pkg = finalAttrs.finalPackage;
    data = "grapheneos_camera_deps.json";
    silent = false;
    useBwrap = false;
  };

  nativeBuildInputs = [
    gradle_9
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

    apksigner sign \
      --v4-signing-enabled false \
      --ks ${./grapheneos_info_testkey.jks} \
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
