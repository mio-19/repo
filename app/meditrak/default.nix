{
  lib,
  jdk21,
  gradle-packages,
  stdenv,
  fetchFromGitHub,
  fetchurl,
  unzip,
  apksigner,
  writableTmpDirAsHomeHook,
  androidSdkBuilder,
}:
let
  androidSdk = androidSdkBuilder (s: [
    s.cmdline-tools-latest
    s.platform-tools
    s.platforms-android-36
    # compileSdkVersion 36 requires matching build-tools.
    s.build-tools-36-0-0
    # NDK for JNI/CMake build; version pinned in set-ndk-version.patch.
    s.ndk-27-2-12479018
    # CMake version required by app/build.gradle externalNativeBuild.
    s.cmake-3-22-1
  ]);

  # SQLite amalgamation required by app/src/main/cpp/CMakeLists.txt.
  # CMake's file(DOWNLOAD ...) block is skipped when the target directory already
  # exists; pre-populating it avoids a network download blocked by the Nix sandbox.
  sqliteAmalgamationZip = fetchurl {
    url = "https://sqlite.org/2025/sqlite-amalgamation-3490100.zip";
    hash = "sha256-bOvR2EA/xYww6Tk5skbz5uWNB2WlzVBUbxbAD9gF0sM=";
  };

  gradle =
    (gradle-packages.mkGradle {
      version = "9.3.1";
      hash = "sha256-smbV/2uQ6tptw7IMsJDjcxMC5VOifF0+TfHw12vq/wY=";
      defaultJava = jdk21;
    }).wrapped;
in
stdenv.mkDerivation (finalAttrs: {
  pname = "meditrak";
  version = "0.17.2";

  src = fetchFromGitHub {
    owner = "AdamGuidarini";
    repo = "MediTrak";
    rev = "v${finalAttrs.version}";
    hash = "sha256-YJWZIq16su3JQmYFqhr7cjFNgD1LSb2VC+nJuSG/vj0=";
  };

  patches = [
    # Pin NDK version so AGP does not attempt to download it from the network.
    ./set-ndk-version.patch
    # Disable upstream JVM auto-resolution so Gradle uses the Nix-provided JDK offline.
    ./gradle-offline-toolchain.patch
  ];

  postPatch = ''
    # Pre-populate the SQLite amalgamation directory so CMake's file(DOWNLOAD ...)
    # block is skipped (it checks: if NOT EXISTS <dir>, then download).
    mkdir -p app/src/main/cpp/sqlite3
    cd app/src/main/cpp/sqlite3 && ${unzip}/bin/unzip -q ${sqliteAmalgamationZip} && cd -
  '';

  gradleBuildTask = ":app:assembleRelease";
  gradleUpdateTask = finalAttrs.gradleBuildTask;

  # Lock refresh steps:
  # 1. If MediTrak bumps Gradle, update gradle.version and gradle.hash.
  # 2. Build the updater:
  #    nix build --impure .#meditrak.mitmCache.updateScript
  # 3. Run the resulting fetch-deps.sh from the repo root to regenerate
  #    app/meditrak/meditrak_deps.json.
  mitmCache = gradle.fetchDeps {
    inherit (finalAttrs) pname;
    pkg = finalAttrs.finalPackage;
    data = ./meditrak_deps.json;
    silent = false;
    useBwrap = false;
  };

  nativeBuildInputs = [
    gradle
    jdk21
    apksigner
    writableTmpDirAsHomeHook
  ];

  env = {
    JAVA_HOME = jdk21;
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
    "-Dorg.gradle.java.installations.paths=${jdk21}"
    "-Dandroid.aapt2FromMavenOverride=${androidSdk}/share/android-sdk/build-tools/36.0.0/aapt2"
    "-Dorg.gradle.project.android.aapt2FromMavenOverride=${androidSdk}/share/android-sdk/build-tools/36.0.0/aapt2"
  ];

  installPhase = ''
    runHook preInstall
    install -Dm644 \
      app/build/outputs/apk/release/app-release-unsigned.apk \
      "$out/meditrak.apk"
    runHook postInstall
  '';

  meta = with lib; {
    description = "MediTrak medication tracker (unsigned)";
    homepage = "https://github.com/AdamGuidarini/MediTrak";
    license = licenses.gpl3Only;
    platforms = platforms.unix;
  };
})
