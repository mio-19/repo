{
  lib,
  jdk21,
  gradle-packages,
  stdenv,
  fetchFromGitHub,
  apksigner,
  zip,
  unzip,
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
    zip
    unzip
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

    apk_path="app/build/outputs/apk/arm64/release/app-arm64-release-unsigned.apk"
    res_archive="app/build/intermediates/shrunk_resources_binary_format/arm64Release/convertShrunkResourcesToBinaryArm64Release/shrunk-resources-binary-format-arm64-release.ap_"

    if [[ ! -f "$apk_path" ]]; then
      echo "ArchiveTune APK not found at $apk_path" >&2
      exit 1
    fi

    if [[ ! -f "$res_archive" ]]; then
      echo "ArchiveTune resource archive not found at $res_archive" >&2
      exit 1
    fi

    # AGP 9 currently leaves code and packaged resources in separate artifacts here.
    # Merge the packaged resources into the original APK while preserving how AGP
    # stored native libraries in the code artifact.
    tmp_res_dir="$(mktemp -d)"
    tmp_apk_raw="$(mktemp --suffix=.apk)"
    mkdir -p "$out"
    cp "$apk_path" "$tmp_apk_raw"
    unzip -q "$res_archive" -d "$tmp_res_dir"
    (
      cd "$tmp_res_dir"
      zip -qurX9 "$tmp_apk_raw" AndroidManifest.xml resources.arsc res
    )

    ${androidSdk}/share/android-sdk/build-tools/35.0.0/zipalign -P 16 -f 4 \
      "$tmp_apk_raw" "$out/archivetune.apk"

    ${androidSdk}/share/android-sdk/build-tools/35.0.0/aapt dump badging "$out/archivetune.apk" >/dev/null
    runHook postInstall
  '';

  meta = with lib; {
    description = "ArchiveTune YouTube Music client for Android";
    homepage = "https://github.com/koiverse/ArchiveTune";
    license = licenses.gpl3Only;
    platforms = platforms.unix;
  };
})
