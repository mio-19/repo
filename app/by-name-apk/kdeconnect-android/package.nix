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
      androidSdk = androidSdkBuilder (s: [
        s.cmdline-tools-latest
        s.platform-tools
        s.platforms-android-36
        s.build-tools-36-0-0
      ]);

      gradle =
        (gradle-packages.mkGradle {
          version = "9.1.0";
          hash = "sha256-oX3dhaJran9d23H/iwX8UQTAICxuZHgkKXkMkzaGyAY=";
          defaultJava = jdk21;
        }).wrapped;
    in
    stdenv.mkDerivation (finalAttrs: {
      pname = "kdeconnect-android";
      version = "1.35.5";

      src = fetchFromGitHub {
        owner = "KDE";
        repo = "kdeconnect-android";
        rev = "v${finalAttrs.version}";
        hash = "sha256-pnPy4Yai0Fj7ViEyjFTTKskNnaoTyln0DlQU3R9QcFk=";
      };

      gradleBuildTask = "assembleRelease";
      gradleUpdateTask = finalAttrs.gradleBuildTask;

      mitmCache = gradle.fetchDeps {
        inherit (finalAttrs) pname;
        pkg = finalAttrs.finalPackage;
        data = ./kdeconnect-android_deps.json;
        silent = false;
        useBwrap = false;
      };

      patches = [
        (fetchpatch {
          name = "Fix CJK (Japanese/Chinese/Korean) text scrambling by using clipboard + Ctrl+V instead of keystrokes";
          url = "https://github.com/KDE/kdeconnect-android/pull/32.diff";
          hash = "sha256-V94ITfq++zaTKHVxPOXCaQhEcbFgFjKLJia23Pf+x/4=";
        })
      ];

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

      preConfigure = ''
        export ANDROID_USER_HOME="$HOME/.android"
        mkdir -p "$ANDROID_USER_HOME"
        echo "sdk.dir=${androidSdk}/share/android-sdk" > local.properties
      '';

      gradleFlags = [
        "-Dorg.gradle.java.installations.auto-download=false"
        "-Dorg.gradle.java.installations.paths=${jdk21}"
        "-Dandroid.aapt2FromMavenOverride=${androidSdk}/share/android-sdk/build-tools/36.0.0/aapt2"
        "-Dorg.gradle.project.android.aapt2FromMavenOverride=${androidSdk}/share/android-sdk/build-tools/36.0.0/aapt2"
      ];

      installPhase = ''
        runHook preInstall
        apk_path="$(find build/outputs/apk -type f -name '*release*.apk' | head -n 1)"
        test -n "$apk_path" && test -f "$apk_path"
        install -Dm644 "$apk_path" "$out/kdeconnect-android.apk"
        runHook postInstall
      '';

      meta = with lib; {
        description = "KDE Connect app for Android";
        homepage = "https://github.com/KDE/kdeconnect-android";
        license = licenses.gpl3Only;
        platforms = platforms.unix;
      };
    });
in
mk-apk-package {
  inherit appPackage;
  mainApk = "kdeconnect-android.apk";
  signScriptName = "sign-kdeconnect-android";
  fdroid = {
    appId = "org.kde.kdeconnect_tp";
    metadataYml = ''
      Categories:
        - File Transfer
        - Remote Controller
        - System
      License: GPL-3.0-only
      WebSite: https://kdeconnect.kde.org/
      SourceCode: https://github.com/KDE/kdeconnect-android
      IssueTracker: https://bugs.kde.org/buglist.cgi?component=android-application&product=kdeconnect
      AutoName: KDE Connect
      Summary: Integrate your smartphone with your desktop
      Description: |-
        KDE Connect links your Android device with your desktop.

        It can share files, sync notifications, use the phone as a remote input
        device, and expose other cross-device integration features.

        This package is built from source using the upstream GitHub release tag.
    '';
  };
}
