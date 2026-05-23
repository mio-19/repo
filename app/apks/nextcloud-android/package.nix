{
  mk-apk-package,
  overrides-fromsrc,
  buildGradlePackage,
  lib,
  jdk25_headless,
  gradle_9_4_1,
  fetchFromGitHub,
  mkSignScript,
  cmake,
  ninja,
  pkgs,
  python3,
  mergeLock,
  unzip,

  writableTmpDirAsHomeHook,
  androidSdkBuilder,
  deepMerge,
}:
let
  androidSdk = androidSdkBuilder (s: [
    s.cmdline-tools-latest
    s.platform-tools
    s.platforms-android-36
    s.build-tools-35-0-0
    s.build-tools-36-0-0
    s.ndk-28-2-13676358
    s.ndk-29-0-14206865
  ]);

  gradle = gradle_9_4_1;

  appPackage = buildGradlePackage (finalAttrs: {
    pname = "nextcloud-android";
    # Go to https://github.com/nextcloud/android/releases/latest to see latest release.
    version = "33.1.1";
    inherit gradle;

    src = fetchFromGitHub {
      owner = "nextcloud";
      repo = "android";
      tag = "stable-${finalAttrs.version}";
      hash = "sha256-EY6vxc6XhCS7uzeZQ101JRBd7V9PFjIBtJF7Czyun6A=";
    };

    lockFile = mergeLock [
      ./gradle.lock
      (pkgs.writeText "extra-deps-lock.json" (builtins.toJSON {
        "com.nextcloud:openssl:3.5.6" = {
          "openssl-3.5.6.aar" = {
            "url" = "https://raw.githubusercontent.com/nextcloud/android/stable-33.1.1/app/libs/local-maven/com/nextcloud/openssl/3.5.6/openssl-3.5.6.aar";
            "hash" = "sha256-sHiwElmNfIBrUKlx6mks8cOHtLhD/iAUvGqPXmox6I4=";
          };
          "openssl-3.5.6.pom" = {
            "url" = "https://raw.githubusercontent.com/nextcloud/android/stable-33.1.1/app/libs/local-maven/com/nextcloud/openssl/3.5.6/openssl-3.5.6.pom";
            "hash" = "sha256-/X9foniD3T4pWf0oac2ad+j3AjEBf4G2ifodhF+XVCQ=";
          };
        };
        "org.jetbrains.intellij.deps.kotlinx:kotlinx-coroutines-bom:1.8.0-intellij-14" = {
          "kotlinx-coroutines-bom-1.8.0-intellij-14.pom" = {
            "url" = "https://repo1.maven.org/maven2/org/jetbrains/intellij/deps/kotlinx/kotlinx-coroutines-bom/1.8.0-intellij-14/kotlinx-coroutines-bom-1.8.0-intellij-14.pom";
            "hash" = "sha256-HUFjTSKbHviGsEg6F+S225NrRkP5QBqzS+UWCc+6YD0=";
          };
        };
        "org.jetbrains.intellij.deps.kotlinx:kotlinx-coroutines-core-jvm:1.8.0-intellij-14" = {
          "kotlinx-coroutines-core-jvm-1.8.0-intellij-14.jar" = {
            "url" = "https://repo1.maven.org/maven2/org/jetbrains/intellij/deps/kotlinx/kotlinx-coroutines-core-jvm/1.8.0-intellij-14/kotlinx-coroutines-core-jvm-1.8.0-intellij-14.jar";
            "hash" = "sha256-7wQ4Vu+POHA5FpYPrBacNZ2Y1f69Vx1n/M3+dbo3jeM=";
          };
          "kotlinx-coroutines-core-jvm-1.8.0-intellij-14.module" = {
            "url" = "https://repo1.maven.org/maven2/org/jetbrains/intellij/deps/kotlinx/kotlinx-coroutines-core-jvm/1.8.0-intellij-14/kotlinx-coroutines-core-jvm-1.8.0-intellij-14.module";
            "hash" = "sha256-Z3M5jeX7L0MyuzdL5AGgNdLxTBM4/rNEYR81hFmZx/c=";
          };
        };
        "com.google.devtools.ksp:symbol-processing-aa-embeddable:2.3.6" = {
          "symbol-processing-aa-embeddable-2.3.6.jar" = {
            "url" = "https://repo1.maven.org/maven2/com/google/devtools/ksp/symbol-processing-aa-embeddable/2.3.6/symbol-processing-aa-embeddable-2.3.6.jar";
            "hash" = "sha256-fK6i1CZoCmp3AHvKYNQOockhjz22rp0WxU8P/vxOG1s=";
          };
          "symbol-processing-aa-embeddable-2.3.6.pom" = {
            "url" = "https://repo1.maven.org/maven2/com/google/devtools/ksp/symbol-processing-aa-embeddable/2.3.6/symbol-processing-aa-embeddable-2.3.6.pom";
            "hash" = "sha256-oa7nRVgcA+5ZqJYoiODuB5WifGwbVbczJS5SvfHPI/0=";
          };
        };
      }))
    ];

    overrides = overrides-fromsrc;
    buildJdk = jdk25_headless;

    postPatch = ''
      rm -f gradle/verification-metadata.xml

      # Fix openssl detection in CMake by pointing to the files in the local maven repo
      # First, unpack the AAR
      mkdir -p app/libs/openssl-unpacked
      unzip app/libs/local-maven/com/nextcloud/openssl/3.5.6/openssl-3.5.6.aar -d app/libs/openssl-unpacked
      
      ABS_PATH=$(pwd)

      substituteInPlace app/src/main/cpp/CMakeLists.txt \
        --replace-fail 'find_package(openssl REQUIRED CONFIG)' '
add_library(openssl_ssl SHARED IMPORTED)
set_target_properties(openssl_ssl PROPERTIES IMPORTED_LOCATION @ABS_PATH@/app/libs/openssl-unpacked/jni/''${ANDROID_ABI}/libssl.so)
add_library(openssl_crypto SHARED IMPORTED)
set_target_properties(openssl_crypto PROPERTIES IMPORTED_LOCATION @ABS_PATH@/app/libs/openssl-unpacked/jni/''${ANDROID_ABI}/libcrypto.so)
' \
        --replace-fail 'cms_verifier.cpp' 'cms_verifier.cpp)
target_include_directories(cms_verifier PRIVATE @ABS_PATH@/app/libs/openssl-unpacked/headers' \
        --replace-fail 'openssl::ssl' 'openssl_ssl' \
        --replace-fail 'openssl::crypto' 'openssl_crypto'
      
      sed -i "s|@ABS_PATH@|$ABS_PATH|g" app/src/main/cpp/CMakeLists.txt
    '';

    preConfigure = ''
      export ANDROID_USER_HOME="$HOME/.android"
      mkdir -p "$ANDROID_USER_HOME"
      echo "cmake.dir=${cmake}" >> local.properties
      echo "android.aapt2FromMavenOverride=${androidSdk}/share/android-sdk/build-tools/35.0.0/aapt2" >> gradle.properties
    '';

    gradleBuildFlagsArray = [ ":app:assembleGenericRelease" ];

    installPhase = ''
      runHook preInstall
      find app/build/outputs/apk -name "*.apk" -exec install -Dm644 {} "$out/nextcloud-android.apk" \;
      runHook postInstall
    '';

    passthru.signScript = mkSignScript {
      name = "sign-nextcloud-android";
      apkPath = "${placeholder "out"}/nextcloud-android.apk";
      defaultOut = "nextcloud-android-signed.apk";
    };

    nativeBuildInputs = [
      androidSdk
      writableTmpDirAsHomeHook
      cmake
      ninja
      unzip
    ];
    env = {
      ANDROID_HOME = "${androidSdk}/share/android-sdk";
      ANDROID_SDK_ROOT = "${androidSdk}/share/android-sdk";
    };

    dontUseCmakeConfigure = true;
    dontUseNinjaBuild = true;
  });
in
mk-apk-package {
  inherit appPackage;
  mainApk = "nextcloud-android.apk";
  signScriptName = "sign-nextcloud-android";
  fdroid = {
    AutoName = "Nextcloud";
    Summary = "Access and sync your Nextcloud files";
    Description = ''
      Nextcloud lets you browse, upload, and synchronize files with your
      Nextcloud server from Android.

      This package is built from source from the upstream nextcloud/android
      repository using the generic (F-Droid compatible) flavor.
    '';
  };
}
