{
  mk-apk-package,
  lib,
  jdk21,
  gradle-packages,
  stdenv,
  fetchFromGitHub,
  fetchurl,
  apksigner,
  writableTmpDirAsHomeHook,
  androidSdkBuilder,
  fetchpatch,
  ...
}:
let
  appPackage =
    let
      rev = "3f0dec3574a6617ff7ff0b78d30b29cfffd71b20";

      androidSdk = androidSdkBuilder (s: [
        s.cmdline-tools-latest
        s.platform-tools
        s.platforms-android-36
        s.build-tools-35-0-0
        s.build-tools-36-0-0
        s.ndk-29-0-13113456
      ]);

      gradle =
        (gradle-packages.mkGradle {
          version = "9.2.1";
          hash = "sha256-cvRMn468sa9Dg49F7lxKqcVESJizRoqz9K97YHbFvD8=";
          defaultJava = jdk21;
        }).wrapped;
    in
    stdenv.mkDerivation (finalAttrs: {
      pname = "termux-app";
      version = "unstable-2026-02-21";

      src = fetchFromGitHub {
        owner = "termux";
        repo = "termux-app";
        rev = rev;
        hash = "sha256-a81+LZaJPdofknb1aGkzyowoGCYzNlcwU1H8k2+sEwY=";
      };

      patches = [
        (fetchpatch {
          name = "Fixed: Improve dark mode support for settings and shared activities";
          url = "https://github.com/termux/termux-app/pull/5025.patch";
          hash = "sha256-07jVCLJX96jZDoWcMlBLtjh2K9dLC1ciVOBzfC1kTpU=";
        })
        /*
          # did not apply
          (fetchpatch {
            name = "Add graphics in terminal support: - Sixel and iTerm2 protocols";
            url = "https://github.com/termux/termux-app/pull/5003.patch";
            hash = "sha256-RYxFj06h4Zm46Rlu2plKXGLS2rqAxegbkcR164yON6c=";
          })
        */
      ];

      bootstrapAarch64 = fetchurl {
        url = "https://github.com/termux/termux-packages/releases/download/bootstrap-2026.02.12-r1+apt.android-7/bootstrap-aarch64.zip";
        hash = "sha256-6irrqIGeUX23EfjDI2nonnxSzuc+B5MP+RGF4auT9PM=";
      };

      bootstrapArm = fetchurl {
        url = "https://github.com/termux/termux-packages/releases/download/bootstrap-2026.02.12-r1+apt.android-7/bootstrap-arm.zip";
        hash = "sha256-o49NOy9zX4O+K/VO/0Y+htwyo+L5+GHBVXxDeNJJwBg=";
      };

      bootstrapI686 = fetchurl {
        url = "https://github.com/termux/termux-packages/releases/download/bootstrap-2026.02.12-r1+apt.android-7/bootstrap-i686.zip";
        hash = "sha256-9bwLAlufO0ILX8ru/AZPiI9fIqDW/XCQ9KrAwz6zVVs=";
      };

      bootstrapX86_64 = fetchurl {
        url = "https://github.com/termux/termux-packages/releases/download/bootstrap-2026.02.12-r1+apt.android-7/bootstrap-x86_64.zip";
        hash = "sha256-t/0PLjpN5TS+MUT5+RrMdoYw/EY+rxNKsuZMVF6DT3o=";
      };

      postPatch = ''
        substituteInPlace app/build.gradle \
          --replace-fail \
            "        versionCode 118" \
            "        versionCode 1002"
      '';

      gradleBuildTask = ":app:assembleRelease";
      gradleUpdateTask = finalAttrs.gradleBuildTask;

      mitmCache = gradle.fetchDeps {
        inherit (finalAttrs) pname;
        pkg = finalAttrs.finalPackage;
        data = "termux_deps.json";
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
        JITPACK_NDK_VERSION = "29.0.13113456";
        TERMUX_SPLIT_APKS_FOR_RELEASE_BUILDS = "0";
        ANDROID_AAPT2_FROM_MAVEN_OVERRIDE = "${androidSdk}/share/android-sdk/build-tools/36.0.0/aapt2";
      };

      preConfigure = ''
        export ANDROID_USER_HOME="$HOME/.android"
        mkdir -p "$ANDROID_USER_HOME"

        sdkRoot="$PWD/android-sdk"
        mkdir -p "$sdkRoot/build-tools" "$sdkRoot/platforms" "$sdkRoot/ndk"
        cp -a "${androidSdk}/share/android-sdk/build-tools/35.0.0" "$sdkRoot/build-tools/"
        cp -a "${androidSdk}/share/android-sdk/build-tools/36.0.0" "$sdkRoot/build-tools/"
        ln -s "${androidSdk}/share/android-sdk/platforms/android-36" "$sdkRoot/platforms/android-36"
        ln -s "${androidSdk}/share/android-sdk/platform-tools" "$sdkRoot/platform-tools"
        ln -s "${androidSdk}/share/android-sdk/ndk/29.0.13113456" "$sdkRoot/ndk/29.0.13113456"
        cp -a "${androidSdk}/share/android-sdk/licenses" "$sdkRoot/"

        export ANDROID_HOME="$sdkRoot"
        export ANDROID_SDK_ROOT="$sdkRoot"
        export ANDROID_NDK_ROOT="$sdkRoot/ndk/29.0.13113456"
        echo "sdk.dir=$sdkRoot" > local.properties

        cp "${finalAttrs.bootstrapAarch64}" app/src/main/cpp/bootstrap-aarch64.zip
        cp "${finalAttrs.bootstrapArm}" app/src/main/cpp/bootstrap-arm.zip
        cp "${finalAttrs.bootstrapI686}" app/src/main/cpp/bootstrap-i686.zip
        cp "${finalAttrs.bootstrapX86_64}" app/src/main/cpp/bootstrap-x86_64.zip
      '';

      gradleFlags = [
        "-xlintVitalRelease"
        "-Dorg.gradle.java.installations.auto-download=false"
        "-Dorg.gradle.java.installations.paths=${jdk21}"
        "-Dandroid.aapt2FromMavenOverride=${androidSdk}/share/android-sdk/build-tools/36.0.0/aapt2"
        "-Dorg.gradle.project.android.aapt2FromMavenOverride=${androidSdk}/share/android-sdk/build-tools/36.0.0/aapt2"
      ];

      installPhase = ''
        runHook preInstall

        apk_path="$(echo app/build/outputs/apk/release/*universal*.apk | awk '{print $1}')"
        if [[ ! -f "$apk_path" ]]; then
          apk_path="$(echo app/build/outputs/apk/release/*.apk | awk '{print $1}')"
        fi

        install -Dm644 "$apk_path" "$out/termux.apk"
        runHook postInstall
      '';

      meta = with lib; {
        description = "Termux terminal emulator for Android built from source";
        homepage = "https://github.com/termux/termux-app";
        license = licenses.gpl3Only;
        platforms = platforms.unix;
      };
    });
in
mk-apk-package {
  inherit appPackage;
  mainApk = "termux.apk";
  signScriptName = "sign-termux";
  fdroid = {
    appId = "com.termux";
    metadataYml = ''
      Categories:
        - Development
      License: GPL-3.0-only
      WebSite: https://termux.com
      SourceCode: https://github.com/termux/termux-app
      IssueTracker: https://github.com/termux/termux-app/issues
      Changelog: https://github.com/termux/termux-app/releases
      Donate: https://termux.com/donate.html
      OpenCollective: Termux
      AutoName: Termux
      Summary: Terminal emulator with Linux packages
      Description: |-
        Termux combines terminal emulation with a Linux package collection.
        This package is built from source from the upstream termux-app
        repository and follows the F-Droid universal APK build approach.
    '';
  };
}
