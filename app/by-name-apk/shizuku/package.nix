{
  mk-apk-package,
  lib,
  curl,
  jdk21,
  gradle-packages,
  stdenv,
  fetchgit,
  apksigner,
  writableTmpDirAsHomeHook,
  androidSdkBuilder,
}:
let
  appPackage =
    let
      rev = "b844bc491f1790c72328e1a8e5b2349f8978f0ea";
      shortRev = builtins.substring 0 7 rev;
      commitCount = "1091";

      androidSdk = androidSdkBuilder (s: [
        s.cmdline-tools-latest
        s.platform-tools
        s.platforms-android-36
        s.build-tools-36-0-0
        s.ndk-29-0-13113456
        s.cmake-3-31-6
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
      version = "unstable-2026-03-20";

      dontConfigure = true;

      src = fetchgit {
        url = "https://github.com/rikkaapps/shizuku.git";
        inherit rev;
        fetchSubmodules = true;
        gitConfigFile = lib.toFile "gitconfig" ''
          [url "https://github.com/"]
            insteadOf = git@github.com:
        '';
        hash = "sha256-HwpkWG4dbE2AwvmFRb7YHlubVE+fdEM3kfi16H1flX8=";
      };

      prePatch = ''
        # fetchFromGitHub strips .git, so derive a deterministic version from env.
        substituteInPlace build.gradle \
          --replace-fail "def gitCommitId = 'git rev-parse --short HEAD'.execute([], project.rootDir).text.trim()" "def gitCommitId = System.getenv('SHIZUKU_GIT_COMMIT_ID') ?: '${shortRev}'" \
          --replace-fail "def gitCommitCount = Integer.parseInt('git rev-list --count HEAD'.execute([], project.rootDir).text.trim())" "def gitCommitCount = Integer.parseInt(System.getenv('SHIZUKU_GIT_COMMIT_COUNT') ?: '1')"

        # AGP 8.10.0 currently fails to resolve in this build environment.
        substituteInPlace api/settings.gradle \
          --replace-fail 'version "8.10.0"' 'version "8.10.1"'

        # Resolve Android plugin IDs via com.android.tools.build:gradle directly,
        # which avoids plugin-marker fetches that may be absent in locked deps.
        pluginResolutionBlock=$'pluginManagement {\n    resolutionStrategy {\n        eachPlugin {\n            if (requested.id.id == "com.android.application" || requested.id.id == "com.android.library" || requested.id.id == "com.android.settings") {\n                def agpVersion = requested.version ?: "8.10.1"\n                useModule("com.android.tools.build:gradle:''${agpVersion}")\n            }\n        }\n    }\n'
        substituteInPlace settings.gradle \
          --replace-fail "pluginManagement {" "$pluginResolutionBlock"
        substituteInPlace api/settings.gradle \
          --replace-fail "pluginManagement {" "$pluginResolutionBlock"

        # Ensure all Gradle repository resolution goes through local cached maven roots.
        cacheRoot="${finalAttrs.mitmCache}"
        if [[ -n "$cacheRoot" && -e "$cacheRoot" ]]; then
          printf -v repositoriesBlock 'repositories {\n        maven { url = uri("%s/https/dl.google.com/dl/android/maven2") }\n        maven { url = uri("%s/https/repo.maven.apache.org/maven2") }\n        maven { url = uri("%s/https/jitpack.io") }\n' "$cacheRoot" "$cacheRoot" "$cacheRoot"
          substituteInPlace settings.gradle \
            --replace-fail "repositories {" "$repositoriesBlock"
          substituteInPlace api/settings.gradle \
            --replace-fail "repositories {" "$repositoriesBlock"
        fi

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
        data = ./shizuku_deps.json;
        silent = false;
        useBwrap = false;
      };

      nativeBuildInputs = [
        curl
        gradle
        jdk21
        apksigner
        writableTmpDirAsHomeHook
      ];

      env = {
        JAVA_HOME = if stdenv.isDarwin then "${jdk21}" else "${jdk21}/lib/openjdk";
        ANDROID_HOME = "${androidSdk}/share/android-sdk";
        ANDROID_SDK_ROOT = "${androidSdk}/share/android-sdk";
        ANDROID_NDK_ROOT = "${androidSdk}/share/android-sdk/ndk-bundle";
        ANDROID_AAPT2_FROM_MAVEN_OVERRIDE = "${androidSdk}/share/android-sdk/build-tools/36.0.0/aapt2";
        SHIZUKU_GIT_COMMIT_ID = shortRev;
        SHIZUKU_GIT_COMMIT_COUNT = commitCount;
      };

      preBuild = ''
        export ANDROID_USER_HOME="$HOME/.android"
        mkdir -p "$ANDROID_USER_HOME"

        prefabRoot="$PWD/.nix-cmake"
        cxxPkgDir="$prefabRoot/cxx"
        boringsslPkgDir="$prefabRoot/boringssl"
        mkdir -p "$cxxPkgDir" "$boringsslPkgDir"

        cacheRoot="${finalAttrs.mitmCache}"
        curlArgs=(--fail --location)
        if [[ -n "''${MITM_CACHE_CA:-}" ]]; then
          curlArgs+=(--cacert "$MITM_CACHE_CA")
        fi
        cxxAar="$cacheRoot/https/repo.maven.apache.org/maven2/org/lsposed/libcxx/libcxx/27.0.12077973/libcxx-27.0.12077973.aar"
        (
          cd "$cxxPkgDir"
          ${lib.getExe' jdk21 "jar"} xf "$cxxAar" prefab/modules/cxx
        )
        cat > "$cxxPkgDir/cxxConfig.cmake" <<'EOF'
        add_library(cxx::cxx STATIC IMPORTED)
        set_target_properties(cxx::cxx PROPERTIES
          IMPORTED_LOCATION "''${CMAKE_CURRENT_LIST_DIR}/prefab/modules/cxx/libs/android.''${ANDROID_ABI}/libcxx.a"
          INTERFACE_INCLUDE_DIRECTORIES "''${CMAKE_CURRENT_LIST_DIR}/prefab/modules/cxx/include"
        )
        EOF

        boringsslAar="$cacheRoot/https/repo.maven.apache.org/maven2/io/github/vvb2060/ndk/boringssl/20250114/boringssl-20250114.aar"
        (
          cd "$boringsslPkgDir"
          ${lib.getExe' jdk21 "jar"} xf "$boringsslAar" prefab/modules/crypto_static prefab/modules/ssl_static
        )
        cat > "$boringsslPkgDir/boringsslConfig.cmake" <<'EOF'
        add_library(boringssl::crypto_static STATIC IMPORTED)
        set_target_properties(boringssl::crypto_static PROPERTIES
          IMPORTED_LOCATION "''${CMAKE_CURRENT_LIST_DIR}/prefab/modules/crypto_static/libs/android.''${ANDROID_ABI}/libcrypto_static.a"
          INTERFACE_INCLUDE_DIRECTORIES "''${CMAKE_CURRENT_LIST_DIR}/prefab/modules/crypto_static/include"
        )

        add_library(boringssl::ssl_static STATIC IMPORTED)
        set_target_properties(boringssl::ssl_static PROPERTIES
          IMPORTED_LOCATION "''${CMAKE_CURRENT_LIST_DIR}/prefab/modules/ssl_static/libs/android.''${ANDROID_ABI}/libssl_static.a"
          INTERFACE_INCLUDE_DIRECTORIES "''${CMAKE_CURRENT_LIST_DIR}/prefab/modules/ssl_static/include"
          INTERFACE_LINK_LIBRARIES boringssl::crypto_static
        )
        EOF

        # Make AGP/plugin marker artifacts resolvable from mavenLocal in pure builds.
        [[ -n "$cacheRoot" && -e "$cacheRoot/https/dl.google.com/dl/android/maven2/com/android" ]]
        m2root="$HOME/.m2/repository"
        mkdir -p "$m2root/com"
        ln -sfn "$cacheRoot/https/dl.google.com/dl/android/maven2/com/android" "$m2root/com/android"

        echo "sdk.dir=${androidSdk}/share/android-sdk" > local.properties
      ''
      + lib.optionalString stdenv.isDarwin ''
        export ANDROID_USER_HOME="$HOME/.android"
        export GRADLE_USER_HOME="$HOME/.gradle"
        mkdir -p "$ANDROID_USER_HOME" "$GRADLE_USER_HOME"
        export GRADLE_OPTS="''${GRADLE_OPTS:+$GRADLE_OPTS }-Duser.home=$HOME"
      '';

      gradleFlags = [
        "-xlintVitalRelease"
        "-Dorg.gradle.java.installations.auto-download=false"
        "-Dorg.gradle.java.installations.paths=${finalAttrs.env.JAVA_HOME}"
        "-Dandroid.aapt2FromMavenOverride=${androidSdk}/share/android-sdk/build-tools/36.0.0/aapt2"
        "-Dorg.gradle.project.android.aapt2FromMavenOverride=${androidSdk}/share/android-sdk/build-tools/36.0.0/aapt2"
      ];

      installPhase = ''
        runHook preInstall

        apk_path="$(echo manager/build/outputs/apk/release/*.apk | awk '{print $1}')"

        install -Dm644 "$apk_path" "$out/shizuku.apk"

        runHook postInstall
      '';

      meta = with lib; {
        description = "Shizuku manager app built from source (unsigned APK)";
        homepage = "https://github.com/rikkaapps/shizuku";
        license = licenses.asl20;
        platforms = platforms.unix;
      };
    });
in
mk-apk-package {
  inherit appPackage;
  mainApk = "shizuku.apk";
  signScriptName = "sign-shizuku";
  fdroid = {
    appId = "moe.shizuku.privileged.api";
    metadataYml = ''
      Categories:
        - System
      License: Apache-2.0
      SourceCode: https://github.com/rikkaapps/shizuku
      IssueTracker: https://github.com/rikkaapps/shizuku/issues
      AutoName: Shizuku
      Summary: Run privileged APIs via a user-service bridge
      Description: |-
        Shizuku provides a bridge to use system-level APIs from apps
        without requiring root for every operation.
        This package is built from source.
    '';
  };
}
