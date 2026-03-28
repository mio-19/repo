{
  mk-apk-package,
  lib,
  jdk21,
  gradle-packages,
  stdenv,
  fetchgit,
  apksigner,
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
        s.build-tools-36-0-0
      ]);

      gradle =
        (gradle-packages.mkGradle {
          version = "9.3.1";
          hash = "sha256-smbV/2uQ6tptw7IMsJDjcxMC5VOifF0+TfHw12vq/wY=";
          defaultJava = jdk21;
        }).wrapped;
    in
    stdenv.mkDerivation (finalAttrs: {
      pname = "fdroid-basic";
      version = "2.0-alpha5";

      src = fetchgit {
        url = "https://gitlab.com/fdroid/fdroidclient.git";
        tag = finalAttrs.version;
        hash = "sha256-dYKgf81nHPkL1lVFms2quG8OkaJpY+/y0PDyEznsp40=";
      };

      gradleBuildTask = ":app:assembleBasicDefaultRelease";
      gradleUpdateTask = finalAttrs.gradleBuildTask;

      mitmCache = gradle.fetchDeps {
        inherit (finalAttrs) pname;
        pkg = finalAttrs.finalPackage;
        data = "fdroid-basic_deps.json";
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
        pluginResolutionBlock=$'pluginManagement {\n    resolutionStrategy {\n        eachPlugin {\n            if (requested.id.id == "com.android.application" || requested.id.id == "com.android.library") {\n                def agpVersion = requested.version ?: "9.1.0"\n                useModule("com.android.tools.build:gradle:''${agpVersion}")\n            }\n        }\n    }\n'
        substituteInPlace settings.gradle \
          --replace-fail "pluginManagement {" "$pluginResolutionBlock"
        substituteInPlace app/build.gradle.kts \
          --replace-fail '  lint {' $'  lint {\n    checkReleaseBuilds = false' \
          --replace-fail 'versionNameSuffix = "-$gitHash"' 'versionNameSuffix = "-unknown"'
      '';

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
        apk_path="$(find app/build/outputs/apk -type f -name '*basic*release*.apk' | head -n 1)"
        test -n "$apk_path" && test -f "$apk_path"
        install -Dm644 "$apk_path" "$out/fdroid-basic.apk"
        runHook postInstall
      '';

      meta = with lib; {
        description = "F-Droid Basic app built from source (unsigned)";
        homepage = "https://gitlab.com/fdroid/fdroidclient";
        license = licenses.gpl3Plus;
        platforms = platforms.unix;
      };
    });
in
mk-apk-package {
  inherit appPackage;
  mainApk = "fdroid-basic.apk";
  signScriptName = "sign-fdroid-basic";
  fdroid = {
    appId = "org.fdroid.basic";
    metadataYml = ''
      Categories:
        - App Store & Updater
        - System
      License: GPL-3.0-or-later
      AuthorName: F-Droid
      AuthorEmail: team@f-droid.org
      WebSite: https://f-droid.org
      SourceCode: https://gitlab.com/fdroid/fdroidclient
      IssueTracker: https://gitlab.com/fdroid/fdroidclient/issues
      Translation: https://hosted.weblate.org/projects/f-droid/f-droid
      Changelog: https://gitlab.com/fdroid/fdroidclient/-/blob/HEAD/CHANGELOG.md
      Donate: https://f-droid.org/donate
      Liberapay: F-Droid-Data
      OpenCollective: F-Droid-Euro
      Bitcoin: bc1qd8few44yaxc3wv5ceeedhdszl238qkvu50rj4v
      AutoName: F-Droid Basic
      Summary: Basic F-Droid client
      Description: |-
        F-Droid Basic is a lightweight client for browsing and installing
        applications from F-Droid repositories.
        This package is built from source.
    '';
  };
}
