{
  lib,
  jdk17,
  gradle-packages,
  stdenv,
  fetchFromGitHub,
  apksigner,
  writableTmpDirAsHomeHook,
  androidSdkBuilder,
}:
let
  androidSdk = androidSdkBuilder (s: [
    s.cmdline-tools-latest
    s.platform-tools
    s.platforms-android-34
    s.build-tools-34-0-0
  ]);

  gradle =
    (gradle-packages.mkGradle {
      version = "8.2";
      hash = "sha256-OPZs1u7yF7TDWFW7EepOn7xTWUzMy1+4Lf0xfvjCxaM=";
      defaultJava = jdk17;
    }).wrapped;
in
stdenv.mkDerivation (finalAttrs: {
  pname = "droidspaces-oss";
  version = "5.7.1";

  src = fetchFromGitHub {
    owner = "ravindu644";
    repo = "Droidspaces-OSS";
    rev = "ad62661b2c5442bd26beefc69f83665ce4325762";
    hash = "sha256-EPTiKMLNd4WCYi7rkjZgYFlw5kJrtK1MUUmvkn+zgVU=";
  };

  sourceRoot = "source/Android";

  gradleBuildTask = ":app:assembleRelease";
  gradleUpdateTask = finalAttrs.gradleBuildTask;

  # Lock refresh steps:
  # 1. If Droidspaces bumps Gradle, update `gradle.version` and `gradle.hash`.
  # 2. Build the updater:
  #    nix build --impure .#droidspaces-oss.mitmCache.updateScript
  # 3. Run the resulting `fetch-deps.sh` from the repo root to regenerate
  #    app/droidspaces-oss/droidspaces-oss_deps.json.
  mitmCache = gradle.fetchDeps {
    inherit (finalAttrs) pname;
    pkg = finalAttrs.finalPackage;
    data = ./droidspaces-oss_deps.json;
    silent = false;
    useBwrap = false;
  };

  nativeBuildInputs = [
    gradle
    jdk17
    apksigner
    writableTmpDirAsHomeHook
  ];

  env = {
    JAVA_HOME = jdk17;
    ANDROID_HOME = "${androidSdk}/share/android-sdk";
    ANDROID_SDK_ROOT = "${androidSdk}/share/android-sdk";
    ANDROID_AAPT2_FROM_MAVEN_OVERRIDE = "${androidSdk}/share/android-sdk/build-tools/34.0.0/aapt2";
  };

  postPatch = ''
    substituteInPlace app/build.gradle.kts \
      --replace-fail \
      'var fallbackKeystore = file(System.getProperty("user.home") + "/.android/debug.keystore")' \
      'var fallbackKeystore = file((System.getenv("ANDROID_USER_HOME") ?: (System.getProperty("user.home") + "/.android")) + "/debug.keystore")'
  '';

  preConfigure = ''
    export ANDROID_USER_HOME="$HOME/.android"
    mkdir -p "$ANDROID_USER_HOME"
    echo "sdk.dir=${androidSdk}/share/android-sdk" > local.properties
    if [ ! -f "$ANDROID_USER_HOME/debug.keystore" ]; then
      keytool -genkeypair \
        -alias androiddebugkey \
        -keyalg RSA \
        -keysize 2048 \
        -validity 10000 \
        -storetype JKS \
        -keystore "$ANDROID_USER_HOME/debug.keystore" \
        -storepass android \
        -keypass android \
        -dname "CN=Android Debug,O=Android,C=US"
    fi
  '';

  gradleFlags = [
    "-Dorg.gradle.java.installations.auto-download=false"
    "-Dorg.gradle.java.installations.paths=${jdk17}"
    "-Dandroid.aapt2FromMavenOverride=${androidSdk}/share/android-sdk/build-tools/34.0.0/aapt2"
    "-Dorg.gradle.project.android.aapt2FromMavenOverride=${androidSdk}/share/android-sdk/build-tools/34.0.0/aapt2"
  ];

  installPhase = ''
    runHook preInstall
    install -Dm644 \
      app/build/outputs/apk/release/app-release.apk \
      "$out/droidspaces-oss.apk"
    runHook postInstall
  '';

  meta = with lib; {
    description = "Droidspaces Android app";
    homepage = "https://github.com/ravindu644/Droidspaces-OSS";
    license = licenses.gpl3Only;
    platforms = platforms.unix;
  };
})
