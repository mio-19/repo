{
  mk-apk-package,
  lib,
  jdk21_headless,
  gradle_8_14_3,
  stdenv,
  fetchgit,

  gitMinimal,
  python3,
  writableTmpDirAsHomeHook,
  androidSdkBuilder,
}:
let
  appPackage =
    let
      androidSdk = androidSdkBuilder (s: [
        s.cmdline-tools-latest
        s.platform-tools
        s.platforms-android-35
        s.build-tools-35-0-0
        s.build-tools-36-0-0
        s.ndk-28-2-13676358
        s.cmake-3-22-1
      ]);

      gradle = gradle_8_14_3;
    in
    stdenv.mkDerivation (finalAttrs: {
      pname = "futo-keyboard";
      version = "0.1.29";

      src = fetchgit {
        url = "https://github.com/futo-org/android-keyboard.git";
        tag = finalAttrs.version;
        fetchSubmodules = true;
        hash = "sha256-iJnZNsK6Y1jWEwzvyy/VN3X7wr2bqOTqCo3g0hCRTTI=";
      };

      dontFixup = true;
      dontUseCmakeConfigure = true;

      gradleBuildTask = "assembleStableRelease";
      gradleUpdateTask = finalAttrs.gradleBuildTask;

      mitmCache = gradle.fetchDeps {
        inherit (finalAttrs) pname;
        pkg = finalAttrs.finalPackage;
        data = ./futo-keyboard_deps.json;
        silent = false;
        useBwrap = false;
      };

      nativeBuildInputs = [
        gradle
        jdk21_headless

        gitMinimal
        python3
        writableTmpDirAsHomeHook
      ];

      env = {
        JAVA_HOME = jdk21_headless;
        ANDROID_HOME = "${androidSdk}/share/android-sdk";
        ANDROID_SDK_ROOT = "${androidSdk}/share/android-sdk";
        ANDROID_NDK_HOME = "${androidSdk}/share/android-sdk/ndk/28.2.13676358";
        ANDROID_NDK_ROOT = "${androidSdk}/share/android-sdk/ndk/28.2.13676358";
        ANDROID_AAPT2_FROM_MAVEN_OVERRIDE = "${androidSdk}/share/android-sdk/build-tools/36.0.0/aapt2";
        VERSION_NAME = finalAttrs.version;
        VERSION_CODE = "12900";
        BRANCH_NAME = "master";
      };

      preConfigure = ''
        export ANDROID_USER_HOME="$HOME/.android"
        mkdir -p "$ANDROID_USER_HOME"
        echo "sdk.dir=${androidSdk}/share/android-sdk" > local.properties
        echo "ndk.dir=${androidSdk}/share/android-sdk/ndk/28.2.13676358" >> local.properties
        echo "cmake.dir=${androidSdk}/share/android-sdk/cmake/3.22.1" >> local.properties
      '';

      gradleFlags = [
        "-Dorg.gradle.java.installations.auto-download=false"
        "-Dorg.gradle.java.installations.paths=${jdk21_headless}"
        "-Dandroid.aapt2FromMavenOverride=${androidSdk}/share/android-sdk/build-tools/36.0.0/aapt2"
        "-Dorg.gradle.project.android.aapt2FromMavenOverride=${androidSdk}/share/android-sdk/build-tools/36.0.0/aapt2"
      ];

      installPhase = ''
        runHook preInstall
        apk_path=$(find build/outputs/apk -name "*.apk" | head -n 1)
        if [ -z "$apk_path" ]; then
          echo "Could not find any APK in build/outputs/apk:"
          find build/outputs -type f || true
          exit 1
        fi
        echo "Found APK at: $apk_path"
        install -Dm644 "$apk_path" "$out/futo-keyboard.apk"
        runHook postInstall
      '';

      meta = with lib; {
        description = "FUTO Keyboard - privacy-focused Android keyboard with offline voice input and swipe typing";
        homepage = "https://keyboard.futo.org/";
        license = licenses.asl20;
        platforms = platforms.unix;
      };
    });
in
mk-apk-package {
  inherit appPackage;
  mainApk = "futo-keyboard.apk";
  signScriptName = "sign-futo-keyboard";
  fdroid = {
    appId = "org.futo.inputmethod.latin";
    metadataYml = ''
      Categories:
        - Writing
      License: Apache-2.0
      WebSite: https://keyboard.futo.org/
      SourceCode: https://github.com/futo-org/android-keyboard
      IssueTracker: https://github.com/futo-org/android-keyboard/issues
      Changelog: https://github.com/futo-org/android-keyboard/releases
      AutoName: FUTO Keyboard
      Summary: Privacy-focused keyboard with offline voice input and FUTO Swipe
      Description: |-
        FUTO Keyboard is a free and open-source Android keyboard built
        with a focus on privacy. It features:
        - Offline voice input (no data sent to any server)
        - FUTO Swipe: a leading-accuracy swipe typing system
        - No internet permission (stable build)
        - Multi-language support
        - Customizable layouts and themes

        This package builds the stable flavor from source using the
        upstream GitHub release tag v0.1.29.
    '';
  };
}
