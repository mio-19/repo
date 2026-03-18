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
  python313,
}:
let
  androidSdk = androidSdkBuilder (s: [
    s.cmdline-tools-latest
    s.platform-tools
    s.platforms-android-36
    s.build-tools-36-0-0
    s.build-tools-35-0-0
    s.ndk-27-0-12077973
    s.cmake-3-22-1
  ]);

  gradle =
    (gradle-packages.mkGradle {
      version = "8.11.1";
      hash = "sha256-85eyhwI6zboen2/F6nLSLdY2adWe1KKJopsadu7hUcY=";
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
    hash = "sha256-LV/vFQkcUN19Qv+IHAih9mUH7KrWc5BZ3iNEPka70dw=";
  };

  patches = [
    # Build unsigned APK (no keystore in sandbox); apksigner re-signs in installPhase.
    ./remove-signing-config.patch
    # Allow skipping Chaquopy pip requirements in reproducible/offline builds.
    ./skip-python-requirements.patch
  ];

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
    python313
  ];

  env = {
    JAVA_HOME = jdk17_headless;
    ANDROID_HOME = "${androidSdk}/share/android-sdk";
    ANDROID_SDK_ROOT = "${androidSdk}/share/android-sdk";
    ANDROID_NDK_ROOT = "${androidSdk}/share/android-sdk/ndk/27.0.12077973";
    ANDROID_AAPT2_FROM_MAVEN_OVERRIDE = "${androidSdk}/share/android-sdk/build-tools/36.0.0/aapt2";
    HAVEN_SKIP_PYTHON_REQUIREMENTS = "1";
  };

  preConfigure = ''
    export ANDROID_USER_HOME="$HOME/.android"
    mkdir -p "$ANDROID_USER_HOME"
    echo "sdk.dir=${androidSdk}/share/android-sdk" > local.properties

    # When running in mitmCache dependency-fetch mode, configure pip (used by
    # Chaquopy) to trust the mitm proxy certificate so PyPI downloads are captured.
    if [[ -n "''${MITM_CACHE_CA:-}" ]]; then
      export PIP_CERT="$MITM_CACHE_CA"
      export REQUESTS_CA_BUNDLE="$MITM_CACHE_CA"
      export SSL_CERT_FILE="$MITM_CACHE_CA"
      export PIP_PROXY="http://''${MITM_CACHE_ADDRESS}"
      export HTTPS_PROXY="http://''${MITM_CACHE_ADDRESS}"
      export HTTP_PROXY="http://''${MITM_CACHE_ADDRESS}"
      export https_proxy="http://''${MITM_CACHE_ADDRESS}"
      export http_proxy="http://''${MITM_CACHE_ADDRESS}"
      export ALL_PROXY="http://''${MITM_CACHE_ADDRESS}"
      export all_proxy="http://''${MITM_CACHE_ADDRESS}"
      export NO_PROXY=""
      export no_proxy=""
    fi
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
