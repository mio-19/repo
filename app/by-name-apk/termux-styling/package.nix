{
  mk-apk-package,
  lib,
  jdk21,
  gradle-packages,
  stdenv,
  fetchFromGitHub,
  apksigner,
  writableTmpDirAsHomeHook,
  androidSdkBuilder,
  fetchpatch,
}:
let
  appPackage =
    let
      rev = "79338cb19f4b86cae4d2e81e6de60ba7f613bb9b";

      androidSdk = androidSdkBuilder (s: [
        s.cmdline-tools-latest
        s.platform-tools
        s.platforms-android-36
        s.build-tools-35-0-0
        s.build-tools-36-0-0
      ]);

      gradle =
        (gradle-packages.mkGradle {
          version = "8.13";
          hash = "sha256-IPGxF2I3JUpvwgTYQ0GW+hGkz7OHVnUZxhVW6HEK7Xg=";
          defaultJava = jdk21;
        }).wrapped;
    in
    stdenv.mkDerivation (finalAttrs: {
      pname = "termux-styling";
      version = "unstable-2025-06-25";

      src = fetchFromGitHub {
        owner = "termux";
        repo = "termux-styling";
        rev = rev;
        hash = "sha256-sVKJFVloCruZUz9JhEdomizUM+S2vavk2c0C27lR8E4=";
      };

      patches = [
        (fetchpatch {
          name = "Fix Android 12 + 15";
          url = "https://web.archive.org/web/20260328023017/https://patch-diff.githubusercontent.com/raw/termux/termux-styling/pull/263.patch";
          hash = "sha256-S40xTaUrnE7jAo+PNveVMp0S9NOvHbAi5ubVv0yxvmU=";
        })
      ];

      gradleBuildTask = ":app:assembleRelease";
      gradleUpdateTask = finalAttrs.gradleBuildTask;

      # Lock refresh steps:
      # 1. Build the updater:
      #    nix build --impure .#termux-styling.mitmCache.updateScript
      # 2. Copy the resulting fetch-deps.sh, replace its outPath= with
      #    /home/dev/Documents/repo/app/termux-styling/termux-styling_deps.json,
      #    and run it from the repo root.
      mitmCache = gradle.fetchDeps {
        inherit (finalAttrs) pname;
        pkg = finalAttrs.finalPackage;
        data = "termux-styling_deps.json";
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
        ANDROID_HOME = "${androidSdk}/share/android-sdk";
        ANDROID_SDK_ROOT = "${androidSdk}/share/android-sdk";
        ANDROID_AAPT2_FROM_MAVEN_OVERRIDE = "${androidSdk}/share/android-sdk/build-tools/36.0.0/aapt2";
      };

      postPatch = ''
        substituteInPlace app/build.gradle \
          --replace-fail '        versionCode 1000' '        versionCode 1001' \
          --replace-fail '        versionName "0.32.2"' '        versionName "0.32.2+git.20250625"'

        mv app/src/main/assets/colors/rosé-pine.properties app/src/main/assets/colors/rose-pine.properties
        mv app/src/main/assets/colors/rosé-pine-dawn.properties app/src/main/assets/colors/rose-pine-dawn.properties
        mv app/src/main/assets/colors/rosé-pine-moon.properties app/src/main/assets/colors/rose-pine-moon.properties
      '';

      preConfigure = ''
        export ANDROID_USER_HOME="$HOME/.android"
        mkdir -p "$ANDROID_USER_HOME"
        echo "sdk.dir=${androidSdk}/share/android-sdk" > local.properties
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
        apk_path="$(find app/build/outputs/apk/release -type f -name '*.apk' | head -n 1)"
        test -n "$apk_path" && test -f "$apk_path"
        install -Dm644 "$apk_path" "$out/termux-styling.apk"
        runHook postInstall
      '';

      meta = with lib; {
        description = "Termux plugin providing terminal color schemes and fonts";
        homepage = "https://github.com/termux/termux-styling";
        license = licenses.gpl3Only;
        platforms = platforms.unix;
      };
    });
in
mk-apk-package {
  inherit appPackage;
  mainApk = "termux-styling.apk";
  signScriptName = "sign-termux-styling";
  fdroid = {
    appId = "com.termux.styling";
    metadataYml = ''
      Categories:
        - Development
      License: GPL-3.0-only
      WebSite: https://termux.com
      SourceCode: https://github.com/termux/termux-styling
      IssueTracker: https://github.com/termux/termux-styling/issues
      Changelog: https://github.com/termux/termux-styling/releases
      Donate: https://termux.com/donate.html
      OpenCollective: Termux
      AutoName: Termux:Styling
      Summary: Color schemes and fonts for Termux
      Description: |-
        This Termux plugin provides color schemes and powerline-ready fonts
        to customize the terminal appearance.
        This package is built from source from the upstream
        termux-styling GitHub repository at the latest commit after the
        0.32.1 F-Droid release.
    '';
  };
}
