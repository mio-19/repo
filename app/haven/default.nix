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
    s.ndk-27-3-13750724
    s.cmake-3-31-6
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
  version = "3.17.0";

  src = fetchFromGitHub {
    owner = "GlassOnTin";
    repo = "Haven";
    tag = "v${finalAttrs.version}";
    fetchSubmodules = true;
    hash = "sha256-zH8Dt2h5RkaYr/V3jGqnfB8UO+MdxVgwnHydkZnCPe4=";
  };

  patches = [
    # Build unsigned APK (no keystore in sandbox); apksigner re-signs in installPhase.
    ./remove-signing-config.patch
    # Allow skipping Chaquopy pip requirements in reproducible/offline builds.
    ./skip-python-requirements.patch
    # Override AGP's default NDK selection for the native local module.
    ./set-ndk-version.patch
  ];

  gradleBuildTask = ":app:assembleArm64FullRelease";
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
    ANDROID_NDK_ROOT = "${androidSdk}/share/android-sdk/ndk/27.3.13750724";
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
  preBuild = lib.optionalString stdenv.isDarwin ''
    # AGP writes SDK metadata under ~/.android; /var/empty is read-only on Darwin sandboxes.
    export HOME="$TMPDIR/home"
    mkdir -p "$HOME"
    export ANDROID_USER_HOME="$HOME/.android"
    export GRADLE_USER_HOME="$HOME/.gradle"
    mkdir -p "$ANDROID_USER_HOME" "$GRADLE_USER_HOME"
    export GRADLE_OPTS="''${GRADLE_OPTS:+$GRADLE_OPTS }-Duser.home=$HOME"
  '';

  gradleFlags = [
    "-xlintVitalRelease"
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
