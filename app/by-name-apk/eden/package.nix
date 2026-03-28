{
  mk-apk-package,
  lib,
  jdk21,
  gradle-packages,
  stdenv,
  fetchgit,
  apksigner,
  gitMinimal,
  glslang,
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
          defaultJava = jdk21;
        }).wrapped;
    in
    stdenv.mkDerivation (finalAttrs: {
      pname = "eden";
      version = "unstable-2026-03-28";

      src = fetchgit {
        url = "https://git.eden-emu.dev/eden-emu/eden";
        rev = "c984c387d7e337888dd094aec95c2f2477b8996d";
        hash = "sha256-jXCTCYTnQZyLLB9NgP0Fu+gRN8P5BCaJGtbwWaSMa68=";
      };

      gradleBuildTask = ":app:assembleMainlineRelease";
      gradleUpdateTask = finalAttrs.gradleBuildTask;

      mitmCache = gradle.fetchDeps {
        inherit (finalAttrs) pname;
        pkg = finalAttrs.finalPackage;
        data = ./eden_deps.json;
        silent = false;
        useBwrap = false;
      };

      nativeBuildInputs = [
        gradle
        jdk21
        apksigner
        gitMinimal
        glslang
        python3
        writableTmpDirAsHomeHook
      ];

      env = {
        JAVA_HOME = jdk21;
        ANDROID_HOME = "${androidSdk}/share/android-sdk";
        ANDROID_SDK_ROOT = "${androidSdk}/share/android-sdk";
        ANDROID_NDK_HOME = "${androidSdk}/share/android-sdk/ndk/28.2.13676358";
        ANDROID_NDK_ROOT = "${androidSdk}/share/android-sdk/ndk/28.2.13676358";
        ANDROID_AAPT2_FROM_MAVEN_OVERRIDE = "${androidSdk}/share/android-sdk/build-tools/35.0.0/aapt2";
      };

      postPatch = ''
        substituteInPlace src/android/app/build.gradle.kts \
          --replace-fail 'val autoVersion = (((System.currentTimeMillis() / 1000) - 1451606400) / 10).toInt()' \
            'val autoVersion = 202603280' \
          --replace-fail 'versionName = getGitVersion()' 'versionName = "${finalAttrs.version}"'
      '';

      preConfigure = ''
        export ANDROID_USER_HOME="$HOME/.android"
        mkdir -p "$ANDROID_USER_HOME"

        cat > src/android/local.properties <<EOF
        sdk.dir=${androidSdk}/share/android-sdk
        ndk.dir=${androidSdk}/share/android-sdk/ndk/28.2.13676358
        cmake.dir=${androidSdk}/share/android-sdk/cmake/3.22.1
        EOF

        cd src/android
      '';

      gradleFlags = [
        "-xlintVitalMainlineRelease"
        "-Dorg.gradle.java.installations.auto-download=false"
        "-Dorg.gradle.java.installations.paths=${jdk21}"
        "-Dandroid.aapt2FromMavenOverride=${androidSdk}/share/android-sdk/build-tools/35.0.0/aapt2"
        "-Dorg.gradle.project.android.aapt2FromMavenOverride=${androidSdk}/share/android-sdk/build-tools/35.0.0/aapt2"
      ];

      installPhase = ''
        runHook preInstall
        apk_path="$(find app/build/outputs/apk/mainline/release -type f -name '*.apk' | head -n 1)"
        test -n "$apk_path"
        install -Dm644 "$apk_path" "$out/eden.apk"
        runHook postInstall
      '';

      meta = with lib; {
        description = "Eden Nintendo Switch emulator for Android";
        homepage = "https://git.eden-emu.dev/eden-emu/eden";
        license = licenses.gpl3Only;
        platforms = platforms.unix;
      };
    });
in
mk-apk-package {
  inherit appPackage;
  mainApk = "eden.apk";
  signScriptName = "sign-eden";
  fdroid = {
    appId = "dev.eden.eden_emulator";
    metadataYml = ''
      Categories:
        - Games
      License: GPL-3.0-only
      SourceCode: https://git.eden-emu.dev/eden-emu/eden
      IssueTracker: https://git.eden-emu.dev/eden-emu/eden/issues
      AutoName: Eden
      Summary: Nintendo Switch emulator
      Description: |-
        Eden is a free and open-source Nintendo Switch emulator.
        This package builds the Android arm64 release APK from source.
    '';
  };
}
