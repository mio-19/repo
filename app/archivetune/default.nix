{
  lib,
  jdk21,
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
    s.platforms-android-36
    s.build-tools-35-0-0
    s.build-tools-36-0-0
  ]);

  gradle =
    (gradle-packages.mkGradle {
      version = "9.3.1";
      hash = "sha256-smbV/2uQ6tptw7IMsJDjcxMC5VOifF0+TfHw12vq/wY=";
      defaultJava = jdk21;
    }).wrapped;
in
stdenv.mkDerivation (finalAttrs: {
  pname = "archivetune";
  version = "13.0.0";

  src = fetchFromGitHub {
    owner = "koiverse";
    repo = "ArchiveTune";
    tag = "v${finalAttrs.version}";
    hash = "sha256-x4Q9KwnAWLTTRAtKtKblo0IjYFLatyK37vYAtp4pdS0=";
  };

  gradleBuildTask = ":app:assembleArm64Release";
  gradleUpdateTask = finalAttrs.gradleBuildTask;

  mitmCache = gradle.fetchDeps {
    inherit (finalAttrs) pname;
    pkg = finalAttrs.finalPackage;
    data = "archivetune_deps.json";
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
    ANDROID_AAPT2_FROM_MAVEN_OVERRIDE = "${androidSdk}/share/android-sdk/build-tools/35.0.0/aapt2";
  };

  preConfigure = ''
    export ANDROID_USER_HOME="$HOME/.android"
    mkdir -p "$ANDROID_USER_HOME"
    echo "sdk.dir=${androidSdk}/share/android-sdk" > local.properties
  '';

  gradleFlags = [
    "-Dorg.gradle.java.installations.auto-download=false"
    "-Dorg.gradle.java.installations.paths=${jdk21}"
    "-Dandroid.aapt2FromMavenOverride=${androidSdk}/share/android-sdk/build-tools/35.0.0/aapt2"
    "-Dorg.gradle.project.android.aapt2FromMavenOverride=${androidSdk}/share/android-sdk/build-tools/35.0.0/aapt2"
  ];

  installPhase = ''
    runHook preInstall

    apk_path=""
    for candidate in \
      app/build/outputs/apk/arm64/release/*-release-unsigned.apk \
      app/build/outputs/apk/arm64/release/*-release.apk \
      app/build/outputs/apk/universal/release/*-release-unsigned.apk \
      app/build/outputs/apk/universal/release/*-release.apk \
      app/build/outputs/apk/release/*-release-unsigned.apk \
      app/build/outputs/apk/release/*-release.apk \
      app/build/outputs/apk/*/release/*.apk \
      app/build/outputs/apk/release/*.apk; do
      if [[ -f "$candidate" ]]; then
        apk_path="$candidate"
        break
      fi
    done

    if [[ -z "$apk_path" ]]; then
      echo "ArchiveTune APK not found under app/build/outputs/apk" >&2
      exit 1
    fi

    install -Dm644 "$apk_path" "$out/archivetune.apk"
    runHook postInstall
  '';

  meta = with lib; {
    description = "ArchiveTune YouTube Music client for Android";
    homepage = "https://github.com/koiverse/ArchiveTune";
    license = licenses.gpl3Only;
    platforms = platforms.unix;
  };
})
