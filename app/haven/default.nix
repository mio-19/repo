{
  lib,
  jdk17_headless,
  gradle-packages,
  stdenv,
  fetchFromGitHub,
  apksigner,
  writableTmpDirAsHomeHook,
  androidSdkBuilder,
  git,
}:
let
  androidSdk = androidSdkBuilder (s: [
    s.cmdline-tools-latest
    s.platform-tools
    s.platforms-android-36
    s.build-tools-36-0-0
  ]);

  gradle =
    (gradle-packages.mkGradle {
      version = "8.11.1";
      hash = lib.fakeHash;
      defaultJava = jdk17_headless;
    }).wrapped;
in
stdenv.mkDerivation (finalAttrs: {
  pname = "haven";
  # fdroiddata: versionName 2.2.2, versionCode 661 (arm64 flavor = 66 * 10 + 1)
  version = "2.2.2";

  src = fetchFromGitHub {
    owner = "GlassOnTin";
    repo = "Haven";
    # fdroiddata build commit
    rev = "2ed1f101b97d926b7e142c5b44f84b2c3f05b5a5";
    hash = lib.fakeHash;
    fetchSubmodules = true;
  };

  # fdroiddata: gradle: [arm64]  →  assembleArm64Release
  gradleBuildTask = ":app:assembleArm64Release";
  gradleUpdateTask = finalAttrs.gradleBuildTask;

  # Lock refresh steps:
  # 1. Build the updater:
  #    nix build --impure .#haven.mitmCache.updateScript
  # 2. Copy the resulting fetch-deps.sh, set outPath=haven_deps.json, run from repo root.
  mitmCache = gradle.fetchDeps {
    inherit (finalAttrs) pname;
    pkg = finalAttrs.finalPackage;
    data = "haven_deps.json";
    silent = false;
    useBwrap = false;
  };

  nativeBuildInputs = [
    gradle
    jdk17_headless
    apksigner
    writableTmpDirAsHomeHook
    git
  ];

  env = {
    JAVA_HOME = jdk17_headless;
    ANDROID_HOME = "${androidSdk}/share/android-sdk";
    ANDROID_SDK_ROOT = "${androidSdk}/share/android-sdk";
    ANDROID_AAPT2_FROM_MAVEN_OVERRIDE = "${androidSdk}/share/android-sdk/build-tools/36.0.0/aapt2";
  };

  preConfigure = ''
    export ANDROID_USER_HOME="$HOME/.android"
    mkdir -p "$ANDROID_USER_HOME"
    echo "sdk.dir=${androidSdk}/share/android-sdk" > local.properties
  '';

  gradleFlags = [
    "-Dorg.gradle.java.installations.auto-download=false"
    "-Dorg.gradle.java.installations.paths=${jdk17_headless}"
    "-Dandroid.aapt2FromMavenOverride=${androidSdk}/share/android-sdk/build-tools/36.0.0/aapt2"
    "-Dorg.gradle.project.android.aapt2FromMavenOverride=${androidSdk}/share/android-sdk/build-tools/36.0.0/aapt2"
  ];

  installPhase = ''
    runHook preInstall
    apk_path="$(echo app/build/outputs/apk/arm64/release/haven-*.apk)"
    install -Dm644 "$apk_path" "$out/haven.apk"
    runHook postInstall
  '';

  meta = with lib; {
    description = "Haven – SSH/Mosh terminal and Reticulum network client for Android";
    homepage = "https://github.com/GlassOnTin/Haven";
    license = licenses.gpl3Only;
    platforms = platforms.unix;
  };
})
