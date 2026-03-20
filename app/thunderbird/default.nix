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
    # AGP 8.12.3 with compileSdk=36 resolves aapt2 from build-tools 35.0.0.
    s.build-tools-35-0-0
  ]);

  gradle =
    (gradle-packages.mkGradle {
      version = "9.1.0";
      hash = "sha256-oX3dhaJran9d23H/iwX8UQTAICxuZHgkKXkMkzaGyAY=";
      defaultJava = jdk21;
    }).wrapped;
in
stdenv.mkDerivation (finalAttrs: {
  pname = "thunderbird-android";
  version = "17.0";

  src = fetchFromGitHub {
    owner = "thunderbird";
    repo = "thunderbird-android";
    tag = "THUNDERBIRD_17_0";
    hash = "sha256-sDUWRfHpyj9VcPWjyatdOAVZK8jYv4a5BckE+js3BLs=";
  };

  patches = [
    # Remove foojay JDK auto-provisioner, glean telemetry module,
    # googleplay funding module, and app-k9mail from project settings.
    # Replaces maven.mozilla.org with jitpack.io (keeping jitpack content filter).
    # Translates FDroid prebuild: sed -e 's|maven.mozilla.org/maven2|jitpack.io|'
    #   -e '/glean/d' -e '/googleplay/d' -e '/:app-k9mail/d' -e '/foojay/d'
    ./remove-foojay-glean-k9.patch
    # Replace googleplay funding references in app-thunderbird/build.gradle.kts
    # with funding.link (foss flavor doesn't use Play billing).
    # Translates FDroid prebuild: sed -e 's/feature.funding.googleplay/feature.funding.link/'
    ./fix-funding-link.patch
  ];

  gradleBuildTask = ":app-thunderbird:assembleFossRelease";
  gradleUpdateTask = finalAttrs.gradleBuildTask;

  # Lock refresh steps:
  # 1. If Thunderbird bumps Gradle, update `gradle.version` and `gradle.hash`.
  # 2. Build the updater:
  #    nix build --impure .#thunderbird.mitmCache.updateScript
  # 3. Copy the resulting `fetch-deps.sh`, replace its `outPath=` with
  #    `/home/dev/Documents/repo/app/thunderbird/thunderbird_deps.json`, and run it
  #    from the repo root.
  mitmCache = gradle.fetchDeps {
    inherit (finalAttrs) pname;
    pkg = finalAttrs.finalPackage;
    data = "thunderbird_deps.json";
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
    install -Dm644 \
      app-thunderbird/build/outputs/apk/foss/release/app-thunderbird-foss-release-unsigned.apk \
      "$out/thunderbird.apk"
    runHook postInstall
  '';

  meta = with lib; {
    description = "Thunderbird for Android (F-Droid foss flavor, unsigned)";
    homepage = "https://github.com/thunderbird/thunderbird-android";
    license = licenses.asl20;
    platforms = platforms.unix;
  };
})
