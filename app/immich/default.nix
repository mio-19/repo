{
  lib,
  buildDartApplication,
  runCommand,
  fetchFromGitHub,
  flutter335,
  git,
  jdk17_headless,
  python3,
  gradle-packages,
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
    s.ndk-28-2-13676358
    s.cmake-3-22-1
  ]);

  gradle =
    (gradle-packages.mkGradle {
      version = "8.13";
      hash = "sha256-IPGxF2I3JUpvwgTYQ0GW+hGkz7OHVnUZxhVW6HEK7Xg=";
      defaultJava = jdk17_headless;
    }).wrapped;
in
buildDartApplication.override { dart = flutter335; } (finalAttrs: {
  pname = "immich";
  version = "2.6.1+3039";

  src = fetchFromGitHub {
    owner = "immich-app";
    repo = "immich";
    tag = "v2.6.1";
    fetchSubmodules = true;
    hash = "sha256-DlpjmR3p+crBwBjU589t6WMzhAwSsZiviPsT2Sp7mk4=";
  };

  sourceRoot = "source/mobile";
  packageRoot = "mobile";

  pubspecLock = lib.importJSON ./pubspec.lock.json;
  gitHashes = lib.importJSON ./git-hashes.json;

  sdkSourceBuilders = {
    flutter =
      name:
      runCommand "flutter-sdk-${name}" { passthru.packageRoot = "."; } ''
        for path in \
          '${flutter335}/packages/${name}' \
          '${flutter335}/bin/cache/pkg/${name}'; do
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

  mitmCache = gradle.fetchDeps {
    inherit (finalAttrs) pname;
    pkg = finalAttrs.finalPackage;
    data = ./immich_deps.json;
    silent = false;
    useBwrap = false;
  };

  gradleUpdateTask = ":app:dependencies --configuration releaseRuntimeClasspath";

  dontDartBuild = true;
  dontDartInstall = true;

  nativeBuildInputs = [
    gradle
    git
    jdk17_headless
    python3
    writableTmpDirAsHomeHook
  ];

  env = {
    JAVA_HOME = jdk17_headless;
    ANDROID_HOME = "${androidSdk}/share/android-sdk";
    ANDROID_SDK_ROOT = "${androidSdk}/share/android-sdk";
    ANDROID_NDK_HOME = "${androidSdk}/share/android-sdk/ndk/28.2.13676358";
    ANDROID_NDK_ROOT = "${androidSdk}/share/android-sdk/ndk/28.2.13676358";
    ANDROID_AAPT2_FROM_MAVEN_OVERRIDE = "${androidSdk}/share/android-sdk/build-tools/35.0.0/aapt2";
  };

  gradleFlags = [
    "--project-dir"
    "android"
    "-Dorg.gradle.java.installations.auto-download=false"
    "-Dorg.gradle.java.installations.paths=${jdk17_headless}"
    "-Dandroid.aapt2FromMavenOverride=${androidSdk}/share/android-sdk/build-tools/35.0.0/aapt2"
    "-Dorg.gradle.project.android.aapt2FromMavenOverride=${androidSdk}/share/android-sdk/build-tools/35.0.0/aapt2"
  ];

  postPatch = ''
    cp -LR ${flutter335} flutter-sdk
    chmod -R u+w flutter-sdk

    cat > android/gradlew << 'GRADLEW_SCRIPT'
    #!/bin/sh
    exec ${gradle}/bin/gradle "$@"
    GRADLEW_SCRIPT
    chmod +x android/gradlew

    substituteInPlace android/app/build.gradle \
      --replace-fail "//f configurations.all {" "configurations.all {" \
      --replace-fail "//f     exclude group: 'com.google.android.gms'" "    exclude group: 'com.google.android.gms'" \
      --replace-fail "//f }" "}"

    substituteInPlace android/gradle.properties \
      --replace-fail "org.gradle.jvmargs=-Xmx4096M" "org.gradle.jvmargs=-Xmx8192M"
  '';

  preConfigure = ''
    export ANDROID_USER_HOME="$HOME/.android"
    mkdir -p "$ANDROID_USER_HOME"
    export PUB_CACHE="$PWD/.pub-cache"

    echo "sdk.dir=${androidSdk}/share/android-sdk" > android/local.properties
    echo "cmake.dir=${androidSdk}/share/android-sdk/cmake/3.22.1" >> android/local.properties
    echo "flutter.sdk=$PWD/flutter-sdk" >> android/local.properties
    echo "flutter.versionName=2.6.1" >> android/local.properties
    echo "flutter.versionCode=3039" >> android/local.properties
  '';

  preBuild = ''
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

    packageRun easy_localization -e generate -S ../i18n
    dart --packages=.dart_tool/package_config.json bin/generate_keys.dart
    dart format lib/generated/codegen_loader.g.dart lib/generated/translations.g.dart

    ${python3}/bin/python3 - <<'PY' > geolocator_android_store_dir.txt
    import json
    import urllib.parse

    with open(".dart_tool/package_config.json") as f:
        data = json.load(f)

    geolocator_root = ""
    for pkg in data["packages"]:
        if pkg["name"] == "geolocator_android":
            geolocator_root = urllib.parse.urlparse(pkg["rootUri"]).path.removesuffix("/.")
            break

    print(geolocator_root)
    PY
    geolocator_android_store_dir="$(cat geolocator_android_store_dir.txt)"
    if [ -n "$geolocator_android_store_dir" ]; then
      mkdir -p .dart-patched
      cp -LR "$geolocator_android_store_dir" .dart-patched/geolocator_android
      chmod -R u+w .dart-patched/geolocator_android

      substituteInPlace .dart-patched/geolocator_android/android/build.gradle \
        --replace-fail "    implementation 'com.google.android.gms:play-services-location:21.2.0'" ""

      rm .dart-patched/geolocator_android/android/src/main/java/com/baseflow/geolocator/location/FusedLocationClient.java
      install -m644 ${./GeolocationManager.java} \
        .dart-patched/geolocator_android/android/src/main/java/com/baseflow/geolocator/location/GeolocationManager.java

      substituteInPlace .dart_tool/package_config.json \
        --replace-fail "$geolocator_android_store_dir" "$PWD/.dart-patched/geolocator_android"
    fi
  '';

  buildPhase = ''
    runHook preBuild
    flutter build apk --release --no-pub --dart-define=cronetHttpNoPlay=true
    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall

    apk_path="$(echo build/app/outputs/flutter-apk/*.apk | awk '{print $1}')"
    install -Dm644 "$apk_path" "$out/immich.apk"

    runHook postInstall
  '';

  meta = with lib; {
    description = "Immich mobile app built from source";
    homepage = "https://github.com/immich-app/immich";
    license = licenses.agpl3Only;
    platforms = platforms.unix;
  };
})
