{
  mk-apk-package,
  lib,
  jdk17_headless,
  gradle-packages,
  stdenv,
  fetchgit,
  apksigner,
  writableTmpDirAsHomeHook,
  androidSdkBuilder,
}:
let
  rev = "831c3753f205c4c8c1cd5bbb1f24e56b9d52eb76";
  version = "unstable-2026-04-02";

  appPackage =
    let
      androidSdk = androidSdkBuilder (s: [
        s.cmdline-tools-latest
        s.platform-tools
        s.platforms-android-34
        s.platforms-android-35
        s.build-tools-34-0-0
        s.build-tools-35-0-0
      ]);

      gradle =
        (gradle-packages.mkGradle {
          version = "8.11.1";
          hash = "sha256-85eyhwI6zboen2/F6nLSLdY2adWe1KKJopsadu7hUcY=";
          defaultJava = jdk17_headless;
        }).wrapped;
    in
    stdenv.mkDerivation (finalAttrs: {
      pname = "shelter";
      inherit version;

      src = fetchgit {
        url = "https://gitea.angry.im/PeterCxy/Shelter.git";
        inherit rev;
        fetchSubmodules = true;
        hash = "sha256-KepVB5J7UAyum/eY0m9i5GAENU+17qT1JHohOOZ+P/w=";
      };

      gradleBuildTask = ":app:assembleRelease";
      gradleUpdateTask = finalAttrs.gradleBuildTask;

      mitmCache = gradle.fetchDeps {
        inherit (finalAttrs) pname;
        pkg = finalAttrs.finalPackage;
        data = ./shelter_deps.json;
        silent = false;
        useBwrap = false;
      };

      nativeBuildInputs = [
        gradle
        jdk17_headless
        apksigner
        writableTmpDirAsHomeHook
      ];

      env = {
        JAVA_HOME = jdk17_headless;
        ANDROID_HOME = "${androidSdk}/share/android-sdk";
        ANDROID_SDK_ROOT = "${androidSdk}/share/android-sdk";
        ANDROID_AAPT2_FROM_MAVEN_OVERRIDE = "${androidSdk}/share/android-sdk/build-tools/35.0.0/aapt2";
      };

      postPatch = ''
        substituteInPlace app/build.gradle \
          --replace-fail "        versionCode getVersionCode()" "        versionCode 446" \
          --replace-fail "        versionName getVersionName()" "        versionName \"git-${lib.substring 0 8 rev}\""
      '';

      preConfigure = ''
        export ANDROID_USER_HOME="$HOME/.android"
        mkdir -p "$ANDROID_USER_HOME"
        echo "sdk.dir=${androidSdk}/share/android-sdk" > local.properties
      '';

      gradleFlags = [
        "-xlintVitalRelease"
        "-Dorg.gradle.java.installations.auto-download=false"
        "-Dorg.gradle.java.installations.paths=${jdk17_headless}"
        "-Dandroid.aapt2FromMavenOverride=${androidSdk}/share/android-sdk/build-tools/35.0.0/aapt2"
        "-Dorg.gradle.project.android.aapt2FromMavenOverride=${androidSdk}/share/android-sdk/build-tools/35.0.0/aapt2"
      ];

      installPhase = ''
        runHook preInstall
        apk_path="$(find app/build/outputs/apk/release -type f -name '*.apk' | head -n 1)"
        test -n "$apk_path" && test -f "$apk_path"
        install -Dm644 "$apk_path" "$out/shelter.apk"
        runHook postInstall
      '';

      meta = with lib; {
        description = "Shelter work-profile manager app built from source";
        homepage = "https://gitea.angry.im/PeterCxy/Shelter";
        license = licenses.gpl3Only;
        platforms = platforms.unix;
      };
    });
in
mk-apk-package {
  inherit appPackage;
  mainApk = "shelter.apk";
  signScriptName = "sign-shelter";
  fdroid = {
    appId = "net.typeblog.shelter";
    metadataYml = ''
      Categories:
        - App Manager
        - Security
      License: GPL-3.0-only
      AuthorName: PeterCxy
      AuthorEmail: peter@typeblog.net
      SourceCode: https://gitea.angry.im/PeterCxy/Shelter
      IssueTracker: https://lists.sr.ht/~petercxy/shelter
      Translation: https://weblate.typeblog.net/projects/shelter/shelter/
      Changelog: https://gitea.angry.im/PeterCxy/Shelter/src/branch/master/CHANGELOG.md
      Donate: https://www.patreon.com/PeterCxy
      AutoName: Shelter
      Summary: Isolated profile for apps using Android Work Profile
      Description: |-
        Shelter uses Android Work Profile to isolate selected apps and data.
        This package is built from source at the latest upstream commit.
    '';
  };
}
