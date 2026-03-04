{
  lib,
  stdenv,
  fetchFromGitHub,
  gradle_9,
  jdk17_headless,
  androidenv,
}:
let
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
  version = "6cd1e4439d1cd8a3dcaa588b666c7fee7aa79792";

  src = fetchFromGitHub {
    owner = "GrapheneOS";
    repo = "Info";
    rev = finalAttrs.version;
    hash = "sha256-X4ocWYZxcyHBqA64KNV7jJ65pqnGjbKXzsLHSL65XuU=";
  };

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
    export HOME="$TMPDIR/home"
    export ANDROID_USER_HOME="$TMPDIR/android-user-home"
    mkdir -p "$HOME" "$ANDROID_USER_HOME"
  '';

  installPhase = ''
    runHook preInstall

    mkdir -p "$out/share/apk"
    cp app/build/outputs/apk/release/*.apk "$out/share/apk/"

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
