{
  lib,
  jdk21,
  gradle-packages,
  stdenv,
  fetchgit,
  apksigner,
  writableTmpDirAsHomeHook,
  androidSdkBuilder,
  cmake,
  ninja,
  perl,
}:
let
  androidSdk = androidSdkBuilder (s: [
    s.cmdline-tools-latest
    s.platform-tools
    s.platforms-android-36
    s.build-tools-36-0-0
    s.ndk-29-0-13113456
    s.cmake-3-22-1
  ]);

  gradle =
    (gradle-packages.mkGradle {
      version = "8.14";
      hash = "sha256-Ya0xDTx9Pl2hMbdrvyK1pMB4bp2JLa6MFljUtITePKo=";
      defaultJava = jdk21;
    }).wrapped;
in
stdenv.mkDerivation (finalAttrs: {
  pname = "shizuku";
  version = "v13.6.0";

  dontConfigure = true;

  src = fetchgit {
    url = "https://github.com/rikkaapps/shizuku.git";
    tag = finalAttrs.version;
    fetchSubmodules = true;
    gitConfigFile = lib.toFile "gitconfig" ''
      [url "https://github.com/"]
        insteadOf = git@github.com:
    '';
    hash = "sha256-O4pgMwYpzv57m/tFzWhSAQzMKJB+b/ICMr0Wkd9T+ac=";
  };

  prePatch = ''
    # fetchFromGitHub strips .git, so derive a deterministic version from env.
    substituteInPlace build.gradle \
      --replace-fail "def gitCommitId = 'git rev-parse --short HEAD'.execute([], project.rootDir).text.trim()" "def gitCommitId = System.getenv('SHIZUKU_GIT_COMMIT_ID') ?: '${
        builtins.substring 0 7 finalAttrs.version
      }'" \
      --replace-fail "def gitCommitCount = Integer.parseInt('git rev-list --count HEAD'.execute([], project.rootDir).text.trim())" "def gitCommitCount = Integer.parseInt(System.getenv('SHIZUKU_GIT_COMMIT_COUNT') ?: '1')"

    # AGP 8.10.0 currently fails to resolve in this build environment.
    substituteInPlace settings.gradle \
      --replace-fail 'version "8.10.0"' 'version "8.10.1"'
    substituteInPlace api/settings.gradle \
      --replace-fail 'version "8.10.0"' 'version "8.10.1"'

    # Resolve Android plugin IDs via com.android.tools.build:gradle directly,
    # which avoids plugin-marker fetches that may be absent in locked deps.
    perl -0777 -i -pe 's/pluginManagement \{\n/pluginManagement {\n    resolutionStrategy {\n        eachPlugin {\n            if (requested.id.id == "com.android.application" || requested.id.id == "com.android.library" || requested.id.id == "com.android.settings") {\n                def agpVersion = requested.version ?: "8.10.1"\n                useModule("com.android.tools.build:gradle:\''${agpVersion}")\n            }\n        }\n    }\n/s' settings.gradle
    perl -0777 -i -pe 's/pluginManagement \{\n/pluginManagement {\n    resolutionStrategy {\n        eachPlugin {\n            if (requested.id.id == "com.android.application" || requested.id.id == "com.android.library" || requested.id.id == "com.android.settings") {\n                def agpVersion = requested.version ?: "8.10.1"\n                useModule("com.android.tools.build:gradle:\''${agpVersion}")\n            }\n        }\n    }\n/s' api/settings.gradle

    # Ensure all Gradle repository resolution goes through local cached maven roots.
    cacheRoot="${finalAttrs.mitmCache}"
    perl -0777 -i -pe "s|repositories \\{\\n|repositories {\\n        maven { url = uri(\"$cacheRoot/https/dl.google.com/dl/android/maven2\") }\\n        maven { url = uri(\"$cacheRoot/https/repo.maven.apache.org/maven2\") }\\n        maven { url = uri(\"$cacheRoot/https/jitpack.io\") }\\n|g" settings.gradle
    perl -0777 -i -pe "s|repositories \\{\\n|repositories {\\n        maven { url = uri(\"$cacheRoot/https/dl.google.com/dl/android/maven2\") }\\n        maven { url = uri(\"$cacheRoot/https/repo.maven.apache.org/maven2\") }\\n        maven { url = uri(\"$cacheRoot/https/jitpack.io\") }\\n|g" api/settings.gradle

    # gradle.fetchDeps runs with MITM env vars; explicitly configure Gradle/JVM
    # proxy and truststore so Java downloads are captured into shizuku_deps.json.
    if [[ -n "''${MITM_CACHE_HOST:-}" && -n "''${MITM_CACHE_PORT:-}" && -n "''${MITM_CACHE_CA:-}" ]]; then
      truststore="$PWD/mitm-truststore.jks"
      keytool -importcert -noprompt \
        -alias mitm-cache-ca \
        -file "$MITM_CACHE_CA" \
        -keystore "$truststore" \
        -storepass changeit

      cat >> gradle.properties <<EOF
    systemProp.http.proxyHost=$MITM_CACHE_HOST
    systemProp.http.proxyPort=$MITM_CACHE_PORT
    systemProp.https.proxyHost=$MITM_CACHE_HOST
    systemProp.https.proxyPort=$MITM_CACHE_PORT
    systemProp.javax.net.ssl.trustStore=$truststore
    systemProp.javax.net.ssl.trustStorePassword=changeit
    EOF
    fi

    # In sandboxed builds, ~/.android/debug.keystore may not exist.
    # Generate a local debug keystore and point signing fallback to it.
    keytool -genkeypair \
      -keystore debug.keystore \
      -storepass android \
      -keypass android \
      -alias androiddebugkey \
      -keyalg RSA \
      -keysize 2048 \
      -validity 10000 \
      -dname "CN=Android Debug,O=Android,C=US"

    substituteInPlace signing.gradle \
      --replace-fail "android.signingConfigs.sign.storeFile = android.signingConfigs.debug.storeFile" "android.signingConfigs.sign.storeFile = rootProject.file('debug.keystore')" \
      --replace-fail "android.signingConfigs.sign.storePassword = android.signingConfigs.debug.storePassword" "android.signingConfigs.sign.storePassword = 'android'" \
      --replace-fail "android.signingConfigs.sign.keyAlias = android.signingConfigs.debug.keyAlias" "android.signingConfigs.sign.keyAlias = 'androiddebugkey'" \
      --replace-fail "android.signingConfigs.sign.keyPassword = android.signingConfigs.debug.keyPassword" "android.signingConfigs.sign.keyPassword = 'android'"
  '';

  gradleBuildTask = ":manager:assembleRelease";
  gradleUpdateTask = finalAttrs.gradleBuildTask;

  mitmCache = gradle.fetchDeps {
    inherit (finalAttrs) pname;
    pkg = finalAttrs.finalPackage;
    data = "shizuku_deps.json";
    silent = false;
    useBwrap = false;
  };

  nativeBuildInputs = [
    gradle
    jdk21
    apksigner
    writableTmpDirAsHomeHook
    cmake
    ninja
    perl
  ];

  env = {
    JAVA_HOME = if stdenv.isDarwin then "${jdk21}" else "${jdk21}/lib/openjdk";
    ANDROID_HOME = "${androidSdk}/share/android-sdk";
    ANDROID_SDK_ROOT = "${androidSdk}/share/android-sdk";
    ANDROID_NDK_ROOT = "${androidSdk}/share/android-sdk/ndk-bundle";
    ANDROID_AAPT2_FROM_MAVEN_OVERRIDE = "${androidSdk}/share/android-sdk/build-tools/36.0.0/aapt2";
    SHIZUKU_GIT_COMMIT_ID = "2650830";
    SHIZUKU_GIT_COMMIT_COUNT = "1";
  };

  preBuild = ''
    export ANDROID_USER_HOME="$HOME/.android"
    mkdir -p "$ANDROID_USER_HOME"

    # Make AGP/plugin marker artifacts resolvable from mavenLocal in pure builds.
    m2root="$PWD/.m2/repository"
    if mkdir -p /build/.m2/repository/com 2>/dev/null; then
      m2root="/build/.m2/repository"
    fi
    mkdir -p "$m2root/com"
    ln -sfn "${finalAttrs.mitmCache}/https/dl.google.com/dl/android/maven2/com/android" "$m2root/com/android"

    echo "sdk.dir=${androidSdk}/share/android-sdk" > local.properties
  ''
  + lib.optionalString stdenv.isDarwin ''
    # AGP writes SDK metadata under ~/.android; /var/empty is read-only on Darwin sandboxes.
    export HOME="$TMPDIR/home"
    mkdir -p "$HOME"
    export ANDROID_USER_HOME="$HOME/.android"
    export GRADLE_USER_HOME="$HOME/.gradle"
    mkdir -p "$ANDROID_USER_HOME" "$GRADLE_USER_HOME"
    export GRADLE_OPTS="''${GRADLE_OPTS:+$GRADLE_OPTS }-Duser.home=$HOME"
  '';

  gradleFlags = [
    "-Dorg.gradle.java.installations.auto-download=false"
    "-Dorg.gradle.java.installations.paths=${finalAttrs.env.JAVA_HOME}"
    "-Dandroid.aapt2FromMavenOverride=${androidSdk}/share/android-sdk/build-tools/36.0.0/aapt2"
    "-Dorg.gradle.project.android.aapt2FromMavenOverride=${androidSdk}/share/android-sdk/build-tools/36.0.0/aapt2"
  ];

  installPhase = ''
    runHook preInstall

    if ls out/apk/*.apk >/dev/null 2>&1; then
      apk_path="$(echo out/apk/*.apk | awk '{print $1}')"
    else
      apk_path="$(echo manager/build/outputs/apk/release/*.apk | awk '{print $1}')"
    fi

    install -Dm644 "$apk_path" "$out/shizuku.apk"

    runHook postInstall
  '';

  meta = with lib; {
    description = "Shizuku manager app built from source (unsigned APK)";
    homepage = "https://github.com/rikkaapps/shizuku";
    license = licenses.asl20;
    platforms = platforms.unix;
  };
})
