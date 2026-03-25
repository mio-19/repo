{
  lib,
  jdk21,
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
    s.platforms-android-35
    s.build-tools-35-0-0
  ]);

  gradle =
    (gradle-packages.mkGradle {
      version = "8.14.3";
      hash = "sha256-vXEQIhNJMGCVbsIp2Ua+7lcVjb2J0OYrkbyg+ixfNTE=";
      defaultJava = jdk21;
    }).wrapped;
in
stdenv.mkDerivation (finalAttrs: {
  pname = "element-android";
  version = "1.6.52";

  src = fetchFromGitHub {
    owner = "element-hq";
    repo = "element-android";
    tag = "v${finalAttrs.version}";
    hash = "sha256-nPudZGjgztivaupcTPc0DNZhjp87WgBiIZvN4H+NHMI=";
  };

  patches = [
    # Remove Firebase App Distribution and gms-OSS-licenses classpath entries
    # from the root build.gradle buildscript block (they are only needed for the
    # gplay/nightly variants, and the plugins would fail if applied without a
    # google-services.json at configure time).
    ./remove-firebase-gms-root.patch
    # Remove firebase.appdistribution and gms.oss-licenses plugin applies,
    # the in-flavor gms.google-services apply, and the nightly
    # firebaseAppDistribution { } extension block from vector-app/build.gradle.
    ./remove-firebase-gms-vector-app.patch
  ];

  gradleBuildTask = ":vector-app:assembleFdroidRelease";
  gradleUpdateTask = finalAttrs.gradleBuildTask;

  # Lock refresh steps:
  # 1. If element-android bumps Gradle, update `gradle.version` and `gradle.hash`.
  # 2. Build the updater:
  #    nix build --impure .#element-android.mitmCache.updateScript
  # 3. Copy the resulting `fetch-deps.sh`, replace its `outPath=` with
  #    `/home/dev/Documents/repo/app/element-android/element_android_deps.json`,
  #    and run it from the repo root.
  mitmCache = gradle.fetchDeps {
    inherit (finalAttrs) pname;
    pkg = finalAttrs.finalPackage;
    data = "element_android_deps.json";
    silent = false;
    useBwrap = false;
  };

  nativeBuildInputs = [
    gradle
    jdk21
    apksigner
    writableTmpDirAsHomeHook
    git
  ];

  env = {
    JAVA_HOME = jdk21;
    ANDROID_HOME = "${androidSdk}/share/android-sdk";
    ANDROID_SDK_ROOT = "${androidSdk}/share/android-sdk";
    ANDROID_AAPT2_FROM_MAVEN_OVERRIDE = "${androidSdk}/share/android-sdk/build-tools/35.0.0/aapt2";
    REALM_DISABLE_ANALYTICS = "true";
  };

  prePatch = ''
    # Fix JVM heap settings: remove legacy -XX:MaxPermSize flag and increase
    # maximum heap to 8 GB (element-android is a large multi-module project).
    substituteInPlace gradle.properties \
      --replace-fail "-Xmx4g" "-Xmx8g" \
      --replace-fail "-XX:MaxPermSize=2048m " ""

    # The release tarball is not a tagged git checkout inside the Nix sandbox,
    # so upstream's gitTag()-based F-Droid suffix logic would append "-dev".
    substituteInPlace vector-app/build.gradle \
      --replace-fail 'versionName "''${versionMajor}.''${versionMinor}.''${versionPatch}''${getFdroidVersionSuffix()}"' \
      'versionName "''${versionMajor}.''${versionMinor}.''${versionPatch}"'

    # Tell the Gradle Doctor plugin that this is a CI build so it skips the
    # JAVA_HOME-matches-Gradle-daemon check (irrelevant in the Nix sandbox).
    substituteInPlace tools/gradle/doctor.gradle \
      --replace-fail \
        'def isCiBuild = System.env.GITHUB_ACTIONS == "true"' \
        'def isCiBuild = true'
  '';

  preConfigure = ''
    export ANDROID_USER_HOME="$HOME/.android"
    mkdir -p "$ANDROID_USER_HOME"
    echo "sdk.dir=${androidSdk}/share/android-sdk" > local.properties
  '';

  gradleFlags = [
    "-xlintVitalRelease"
    "-Dorg.gradle.java.installations.auto-download=false"
    "-Dorg.gradle.java.installations.paths=${jdk21}"
    "-Dandroid.aapt2FromMavenOverride=${androidSdk}/share/android-sdk/build-tools/35.0.0/aapt2"
    "-Dorg.gradle.project.android.aapt2FromMavenOverride=${androidSdk}/share/android-sdk/build-tools/35.0.0/aapt2"
    # Disable lint's network checks and abort-on-error to avoid spurious CI failures.
    "-PallWarningsAsErrors=false"
  ];

  installPhase = ''
    runHook preInstall
    install -Dm644 \
      vector-app/build/outputs/apk/fdroid/release/vector-fdroid-universal-release-unsigned.apk \
      "$out/element-android.apk"
    runHook postInstall
  '';

  meta = with lib; {
    description = "Element Android (F-Droid flavor, unsigned)";
    homepage = "https://github.com/element-hq/element-android";
    license = licenses.asl20;
    platforms = platforms.unix;
  };
})
