{
  mk-apk-package,
  lib,
  jdk21,
  gradle-packages,
  stdenv,
  fetchFromGitHub,
  writableTmpDirAsHomeHook,
  androidSdkBuilder,
  fetchpatch,
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
        s.ndk-29-0-14206865
      ]);

      gradle =
        (gradle-packages.mkGradle {
          version = "8.13";
          hash = "sha256-IPGxF2I3JUpvwgTYQ0GW+hGkz7OHVnUZxhVW6HEK7Xg=";
          defaultJava = jdk21;
        }).wrapped;
    in
    stdenv.mkDerivation (finalAttrs: {
      pname = "nix-on-droid";
      version = "0.118.0_v0.3.7_nix";

      src = fetchFromGitHub {
        owner = "nix-community";
        repo = "nix-on-droid-app";
        rev = "e87b6091bffa7b6eafb1b59cc7824f5692441cd0";
        hash = "sha256-E1f5zcSkfiVa71uuvRxQ+FveXGPD81K68U2N9QAhpro=";
      };

      patches = [
        (fetchpatch {
          name = "feat(view): Enable mouse cursor movement in shell readline";
          url = "https://github.com/termux/termux-app/pull/4775.diff";
          hash = "sha256-xaqizEKirWPYlNFwpF37o1OGDph21nBh+hsw/Loov1Q=";
        })
        (fetchpatch {
          name = "Increase read buffer size from 4KB to 64KB";
          url = "https://github.com/termux/termux-app/commit/ef4775b651c752d5876991a403ecad58bc1fb118.patch";
          hash = "sha256-y9h4NkKKCy3ciK4S3/pSIncE397xNz3XKQvQMQegr9k=";
        })
        (fetchpatch {
          name = "Fixed: Allow language switch key on external keyboards (#4923)";
          url = "https://github.com/termux/termux-app/commit/7d87ed762901f3498847cc6e78a7600c4b26416a.patch";
          hash = "sha256-kQfQcgMQiJClAia+mIB7kZO8gR5k66jI4+tYavT4X9s=";
        })
        (fetchpatch {
          name = "feat: multi window support";
          url = "https://github.com/termux/termux-app/pull/4961.diff";
          hash = "sha256-N/Elb1VT54aLSgWxPbvEWoEUtkTsVoYKRSWZyt3L5/E=";
        })
        ./0001-nix-on-droid-adjust-gradle-agp-deps.patch # based on https://github.com/salmon-21/termux-app/commit/53f75a8da3b823c18a8244b298da50e87382984d
        (fetchpatch {
          name = "Fixed: Improve dark mode support for settings and shared activities";
          url = "https://github.com/termux/termux-app/pull/5025.patch";
          hash = "sha256-07jVCLJX96jZDoWcMlBLtjh2K9dLC1ciVOBzfC1kTpU=";
        })
      ];

      gradleBuildTask = ":app:assembleRelease";
      gradleUpdateTask = finalAttrs.gradleBuildTask;

      mitmCache = gradle.fetchDeps {
        inherit (finalAttrs) pname;
        pkg = finalAttrs.finalPackage;
        data = ./nix-on-droid_deps.json;
        silent = false;
        useBwrap = false;
      };

      nativeBuildInputs = [
        gradle
        jdk21
        writableTmpDirAsHomeHook
      ];

      env = {
        JAVA_HOME = jdk21;
        ANDROID_HOME = "${androidSdk}/share/android-sdk";
        ANDROID_SDK_ROOT = "${androidSdk}/share/android-sdk";
        ANDROID_NDK_ROOT = "${androidSdk}/share/android-sdk/ndk/29.0.14206865";
        ANDROID_AAPT2_FROM_MAVEN_OVERRIDE = "${androidSdk}/share/android-sdk/build-tools/36.0.0/aapt2";
        TERMUX_PACKAGE_VARIANT = "apt-android-7";
        TERMUX_SPLIT_APKS_FOR_RELEASE_BUILDS = "0";
        JITPACK_NDK_VERSION = "29.0.14206865";
      };

      preConfigure = ''
        export ANDROID_USER_HOME="$HOME/.android"
        mkdir -p "$ANDROID_USER_HOME"
        echo "sdk.dir=${androidSdk}/share/android-sdk" > local.properties
      '';

      gradleFlags = [
        "-xlintVitalRelease"
        "--no-daemon"
        "-Dorg.gradle.java.installations.auto-download=false"
        "-Dorg.gradle.java.installations.paths=${jdk21}"
        "-Dandroid.aapt2FromMavenOverride=${androidSdk}/share/android-sdk/build-tools/36.0.0/aapt2"
        "-Dorg.gradle.project.android.aapt2FromMavenOverride=${androidSdk}/share/android-sdk/build-tools/36.0.0/aapt2"
      ];

      installPhase = ''
        runHook preInstall

        apk_path="$(echo app/build/outputs/apk/release/*.apk | awk '{print $1}')"
        install -Dm644 "$apk_path" "$out/nix-on-droid.apk"

        runHook postInstall
      '';

      meta = with lib; {
        description = "Nix-on-Droid terminal emulator app";
        homepage = "https://github.com/nix-community/nix-on-droid";
        license = licenses.mit;
        platforms = platforms.unix;
        sourceProvenance = with sourceTypes; [ fromSource ];
      };
    });
in
mk-apk-package {
  inherit appPackage;
  mainApk = "nix-on-droid.apk";
  signScriptName = "sign-nix-on-droid";
  fdroid = {
    appId = "com.termux.nix";
    metadataYml = ''
      Categories:
        - Development
      License: MIT
      WebSite: https://nix-on-droid.unboiled.info
      SourceCode: https://github.com/nix-community/nix-on-droid
      IssueTracker: https://github.com/nix-community/nix-on-droid/issues
      Name: Nix-on-Droid
      AutoName: Nix
      Description: |-
        Nix-on-Droid brings the Nix package manager to Android.

        This app is the terminal-emulator part, built from the
        `nix-on-droid-app` source repository that F-Droid uses for
        the `com.termux.nix` package.

        Nix-on-Droid uses a fork of the Termux application as its
        terminal emulator.
    '';
  };
}
