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
    url = "https://github.com/GrapheneOS/platform_external_Info/raw/refs/heads/16-qpr2/Android.bp";
    hash = "sha256-jPCp6n0iifKJm1vHido/11xBFYloIxBSGzFSR47uP/A=";
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
  pname = "grapheneos-info";
  version = sources.grapheneos_info.version;
  src = sources.grapheneos_info.src;

  patches = [
    (fetchpatch {
      name = "added release state display to info app";
      url = "https://github.com/GrapheneOS/Info/pull/56.diff";
      hash = "sha256-qMMHV6426FHw1QCg+JfpvmjO/qUvul6T/2Le7A2YQXI=";
    })
  ];

  gradleBuildTask = ":app:assembleRelease";
  gradleUpdateTask = finalAttrs.gradleBuildTask;

  mitmCache = gradle_9.fetchDeps {
    inherit (finalAttrs) pname;
    pkg = finalAttrs.finalPackage;
    data = "grapheneos_info_deps.json";
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
    signed_apk="$out/prebuilt/Info.apk"
    keystore="$TMPDIR/grapheneos-info-signing-key.jks"

    # We don't expect out of band upgrade so use a key generated every time.
    keytool -genkeypair \
      -keystore "$keystore" \
      -storepass android \
      -keypass android \
      -alias androiddebugkey \
      -keyalg RSA \
      -keysize 4096 \
      -validity 10000 \
      -dname "CN=GrapheneOS Info,O=GrapheneOS,C=US"

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
    description = "GrapheneOS Info app built from source";
    homepage = "https://github.com/GrapheneOS/Info";
    license = licenses.asl20;
    sourceProvenance = with sourceTypes; [
      fromSource
      binaryBytecode
    ];
    platforms = platforms.linux;
  };
})
