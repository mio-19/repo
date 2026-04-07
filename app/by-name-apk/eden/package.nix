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
        # Tried NDK 29.0.14206865 here, but Eden then failed deeper in bundled
        # Boost.Process/Asio native code on std::aligned_alloc with the newer
        # libc++ sysroot, so this stays on the baseline NDK for now.
        s.ndk-28-2-13676358
        s.cmake-3-31-6
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
      version = "unstable-2026-04-07";

      src = fetchgit {
        url = "https://git.eden-emu.dev/eden-emu/eden";
        rev = "50a6f331cf0a11e4d6eac8decfe6965097b99082";
        hash = "sha256-XKO4Rz0vklOEEACUxMBkdtU6gDD3+rZLOsA9ct7bQQo=";
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
          --replace-fail 'versionName = getGitVersion()' 'versionName = "${finalAttrs.version}"' \
          --replace-fail 'version = "3.22.1"' 'version = "3.31.6"'
      '';

      preConfigure = ''
        export ANDROID_USER_HOME="$HOME/.android"
        mkdir -p "$ANDROID_USER_HOME"

        cat > src/android/local.properties <<EOF
        sdk.dir=${androidSdk}/share/android-sdk
        ndk.dir=${androidSdk}/share/android-sdk/ndk/28.2.13676358
        cmake.dir=${androidSdk}/share/android-sdk/cmake/3.31.6
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
        apk_dir="app/build/outputs/apk/mainline/release"
        apk_name="$(sed -n 's/.*"outputFile"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' "$apk_dir/output-metadata.json" | head -n 1)"
        test -n "$apk_name"
        apk_path="$apk_dir/$apk_name"
        test -f "$apk_path"
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
