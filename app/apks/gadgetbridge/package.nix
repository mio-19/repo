{
  mk-apk-package,
  lib,
  jdk21_headless,
  gradle_9_5_1,
  stdenv,
  fetchgit,

  writableTmpDirAsHomeHook,
  androidSdkBuilder,
  git,
  gcc,
  cmake,
  gnumake,
  python3,
  buildGradlePackage,
  overrides-fromsrc,
  protobuf,
}:
let
  appPackage =
    let
      androidSdk = androidSdkBuilder (s: [
        s.cmdline-tools-latest
        s.platform-tools
        s.platforms-android-37-0
        s.platforms-android-36
        s.platforms-android-35
        s.platforms-android-34
        s.build-tools-36-0-0
        s.build-tools-36-1-0
      ]);

      gradle = gradle_9_5_1;

      pythonWithCrc32c = python3.withPackages (ps: [ ps.crc32c ]);
    in
    buildGradlePackage rec {
      pname = "gadgetbridge";
      version = "0.94.0";

      src = fetchgit {
        url = "https://codeberg.org/Freeyourgadget/Gadgetbridge.git";
        rev = version;
        fetchSubmodules = true;
        hash = "sha256-B2QN8+DRFKBxMyAtiYIHu/wvtQWpCO1NfsHf3tXsGc8=";
      };

      patches = [
        ./deterministic-release-build.patch
        ./fix-fossil-hr-build.patch
      ];

      gradleBuildFlags = [ ":app:assembleMainlineRelease" ];
      gradleUpdateTask = ":app:assembleMainlineRelease";

      lockFile = ./gradle.lock;
      overrides = overrides-fromsrc // {
        "com.google.protobuf:protoc:4.36.1" = {
          "protoc-4.36.1-linux-x86_64.exe" = _: "${protobuf}/bin/protoc";
        };
      };
      inherit gradle;

      nativeBuildInputs = [
        gradle
        jdk21_headless

        writableTmpDirAsHomeHook
        git
        gcc
        gnumake
        pythonWithCrc32c
      ];

      env = {
        JAVA_HOME = jdk21_headless;
        ANDROID_HOME = "${androidSdk}/share/android-sdk";
        ANDROID_SDK_ROOT = "${androidSdk}/share/android-sdk";
        ANDROID_AAPT2_FROM_MAVEN_OVERRIDE = "${androidSdk}/share/android-sdk/build-tools/36.0.0/aapt2";
        GADGETBRIDGE_VERSION_CODE = "252";
        GADGETBRIDGE_GIT_HASH_SHORT = "release";
      };

      postPatch = ''
        sed -i '/compileSdk {/{N;N;N;N;s/.*/    compileSdk 37/}' app/build.gradle
        sed -i '/content {/,/}/d' settings.gradle.kts
        rm -f external/jerryscript/tools/babel/package.json
      '';

      preConfigure = ''
        export ANDROID_USER_HOME="$HOME/.android"
        mkdir -p "$ANDROID_USER_HOME"
        echo "sdk.dir=${androidSdk}/share/android-sdk" > local.properties
        export PATH=${cmake}/bin:$PATH

        pushd external
        ${stdenv.shell} ./build_fossil_hr_gbapps.sh
        popd
      '';

      preBuild = "ls -la ~/.gradle/caches/modules-2/files-2.1/com.android.application || true";
      gradleFlags = [
        "-xlintVitalBanglejsRelease"
        "-xlintVitalMainlineRelease"
        "-Dorg.gradle.java.installations.auto-download=false"
        "-Dorg.gradle.java.installations.paths=${jdk21_headless}"
        "-Dandroid.aapt2FromMavenOverride=${androidSdk}/share/android-sdk/build-tools/36.0.0/aapt2"
        "-Dorg.gradle.project.android.aapt2FromMavenOverride=${androidSdk}/share/android-sdk/build-tools/36.0.0/aapt2"
      ];

      installPhase = ''
        runHook preInstall
        apk_path="$(echo app/build/outputs/apk/mainline/release/*.apk | awk '{print $1}')"
        install -Dm644 "$apk_path" "$out/gadgetbridge.apk"
        runHook postInstall
      '';

      meta = with lib; {
        description = "Gadgetbridge wearable companion for Android";
        homepage = "https://codeberg.org/Freeyourgadget/Gadgetbridge";
        license = licenses.agpl3Only;
        platforms = platforms.unix;
      };
    };
in
mk-apk-package {
  inherit appPackage;
  mainApk = "gadgetbridge.apk";
  signScriptName = "sign-gadgetbridge";
  fdroid = {
    appId = "nodomain.freeyourgadget.gadgetbridge";
    metadataYml = ''
      Categories:
        - Connectivity
        - Health & Fitness
      License: Apache-2.0
      WebSite: https://gadgetbridge.org/
      SourceCode: https://codeberg.org/Freeyourgadget/Gadgetbridge
      IssueTracker: https://codeberg.org/Freeyourgadget/Gadgetbridge/issues
      Changelog: https://codeberg.org/Freeyourgadget/Gadgetbridge/releases
      AutoName: Gadgetbridge
      Summary: Companion app for wearable devices
      Description: |-
        Gadgetbridge is a libre companion app for wearable devices.

        This package is built from source and follows the current
        F-Droid mainline build, including the Fossil HR asset build step.
    '';
  };
}
