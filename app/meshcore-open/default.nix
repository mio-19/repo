{
  lib,
  buildDartApplication,
  runCommand,
  fetchFromGitHub,
  flutter338,
  jdk17_headless,
  gradle-packages,
  writableTmpDirAsHomeHook,
  androidSdkBuilder,
  git,
}:
let
  androidSdk = androidSdkBuilder (s: [
    s.cmdline-tools-latest
    s.platform-tools
    s.platforms-android-36
    # AGP may resolve aapt2 from build-tools 35.0.0 even with compileSdk 36.
    s.build-tools-35-0-0
    s.build-tools-36-0-0
    # Flutter 3.38.x specifies ndkVersion = "28.2.13676358" in FlutterExtension.kt
    s.ndk-28-2-13676358
    s.cmake-3-22-1
  ]);

  gradle =
    (gradle-packages.mkGradle {
      version = "8.12";
      hash = "sha256-egDVH7kxR4Gaq3YCT+7OILa4TkIGlBAfJ2vpUuCL7wM=";
      defaultJava = jdk17_headless;
    }).wrapped;
in
buildDartApplication.override { dart = flutter338; } (finalAttrs: {
  pname = "meshcore-open";
  version = "7.0.0+8";

  src = fetchFromGitHub {
    owner = "zjs81";
    repo = "meshcore-open";
    rev = "Alpha7";
    hash = "sha256-7szV0z9E/5Jb3Pyo3EFrzbB9mHIoJBgeqrnRdGko+PA=";
  };

  pubspecLock = lib.importJSON ./pubspec.lock.json;

  gitHashes = {
    flserial = "sha256-+v8++zKQkhI4KKyaiE14RxC/kCE96EMFVW4h7914cC0=";
  };

  sdkSourceBuilders = {
    flutter =
      name:
      runCommand "flutter-sdk-${name}" { passthru.packageRoot = "."; } ''
        for path in \
          '${flutter338}/packages/${name}' \
          '${flutter338}/bin/cache/pkg/${name}'; do
          if [ -d "$path" ]; then
            ln -s "$path" "$out"
            break
          fi
        done
        if [ ! -e "$out" ]; then
          echo 1>&2 'The Flutter SDK does not contain the requested package: ${name}!'
          exit 1
        fi
      '';
  };

  # MITM cache for offline Gradle/Maven dependency resolution (including
  # Gradle Plugin Portal requests for Kotlin and AGP plugins).
  # To regenerate after a version bump:
  #   nix build --impure .#meshcore-open.mitmCache.updateScript
  #   Run the resulting fetch-deps.sh from the repo root.
  mitmCache = gradle.fetchDeps {
    inherit (finalAttrs) pname;
    pkg = finalAttrs.finalPackage;
    data = ./meshcore-open_deps.json;
    silent = false;
    useBwrap = false;
  };

  gradleUpdateTask = ":app:assembleRelease";

  dontDartBuild = true;
  dontDartInstall = true;

  nativeBuildInputs = [
    gradle
    jdk17_headless
    writableTmpDirAsHomeHook
    git
  ];

  env = {
    JAVA_HOME = jdk17_headless;
    ANDROID_HOME = "${androidSdk}/share/android-sdk";
    ANDROID_SDK_ROOT = "${androidSdk}/share/android-sdk";
    ANDROID_AAPT2_FROM_MAVEN_OVERRIDE = "${androidSdk}/share/android-sdk/build-tools/35.0.0/aapt2";
  };

  sdkSetupScript = ''
    flutter config --no-analytics >/dev/null 2>&1 || true
  '';

  # Flags used by the gradle() shell function in the fetchDeps update run.
  gradleFlags = [
    "--project-dir"
    "android"
    "-Dorg.gradle.java.installations.auto-download=false"
    "-Dorg.gradle.java.installations.paths=${jdk17_headless}"
    "-Dandroid.aapt2FromMavenOverride=${androidSdk}/share/android-sdk/build-tools/35.0.0/aapt2"
    "-Dorg.gradle.project.android.aapt2FromMavenOverride=${androidSdk}/share/android-sdk/build-tools/35.0.0/aapt2"
  ];

  postPatch = ''
    # Copy the full Flutter SDK to a writable location so included builds under
    # packages/flutter_tools/gradle can compile and write outputs.
    cp -LR ${flutter338} flutter-sdk
    chmod -R u+w flutter-sdk

    # Replace the Gradle wrapper with our pinned Gradle binary.
    cat > android/gradlew << 'GRADLEW_SCRIPT'
    #!/bin/sh
    exec ${gradle}/bin/gradle "$@"
    GRADLEW_SCRIPT
    chmod +x android/gradlew
  '';

  preConfigure = ''
    export ANDROID_USER_HOME="$HOME/.android"
    mkdir -p "$ANDROID_USER_HOME"
    # local.properties is read by settings.gradle.kts (flutter.sdk) and AGP (sdk.dir).
    echo "sdk.dir=${androidSdk}/share/android-sdk" > android/local.properties
    echo "cmake.dir=${androidSdk}/share/android-sdk/cmake/3.22.1" >> android/local.properties
    echo "flutter.sdk=$PWD/flutter-sdk" >> android/local.properties
  '';

  preBuild = ''
    # Propagate MITM proxy and toolchain settings to JVM instances invoked by
    # Flutter's internal Gradle calls (via android/gradlew).  The gradle setup
    # hook writes proxy flags to gradleFlagsArray for the gradle() shell function,
    # but Flutter calls gradlew directly.  GRADLE_OPTS is forwarded to the JVM.
    GRADLE_OPTS="''${GRADLE_OPTS:-}"
    GRADLE_OPTS="$GRADLE_OPTS -Dorg.gradle.java.installations.auto-download=false"
    GRADLE_OPTS="$GRADLE_OPTS -Dorg.gradle.java.installations.paths=${jdk17_headless}"
    GRADLE_OPTS="$GRADLE_OPTS -Dandroid.aapt2FromMavenOverride=${androidSdk}/share/android-sdk/build-tools/35.0.0/aapt2"
    GRADLE_OPTS="$GRADLE_OPTS -Dorg.gradle.project.android.aapt2FromMavenOverride=${androidSdk}/share/android-sdk/build-tools/35.0.0/aapt2"
    if [[ -n "''${MITM_CACHE_KEYSTORE:-}" ]]; then
      GRADLE_OPTS="$GRADLE_OPTS -Dhttp.proxyHost=$MITM_CACHE_HOST"
      GRADLE_OPTS="$GRADLE_OPTS -Dhttp.proxyPort=$MITM_CACHE_PORT"
      GRADLE_OPTS="$GRADLE_OPTS -Dhttps.proxyHost=$MITM_CACHE_HOST"
      GRADLE_OPTS="$GRADLE_OPTS -Dhttps.proxyPort=$MITM_CACHE_PORT"
      GRADLE_OPTS="$GRADLE_OPTS -Djavax.net.ssl.trustStore=$MITM_CACHE_KEYSTORE"
      GRADLE_OPTS="$GRADLE_OPTS -Djavax.net.ssl.trustStorePassword=$MITM_CACHE_KS_PWD"
    fi
    export FLUTTER_ROOT="$PWD/flutter-sdk"
    export GRADLE_OPTS
  '';

  buildPhase = ''
    runHook preBuild
    flutter build apk --release --no-pub
    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall
    install -Dm644 build/app/outputs/flutter-apk/app-release.apk \
      "$out/meshcore-open.apk"
    runHook postInstall
  '';

  meta = with lib; {
    description = "MeshCore Open Android client built from source";
    homepage = "https://github.com/zjs81/meshcore-open";
    license = licenses.mit;
    platforms = platforms.unix;
  };
})
