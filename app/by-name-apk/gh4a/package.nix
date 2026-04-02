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
}:
let
  version = "unstable-2025-12-09";

  src = fetchFromGitHub {
    owner = "slapperwan";
    repo = "gh4a";
    rev = "39f03ffe122125e46a51de16d90881047ed4660e";
    hash = "sha256-ctBPFKZtngci0prdHuc7cx2grAX1ayBNZSGK3aQfd2k=";
  };

  rxloaderAar = fetchurl {
    url = "https://jitpack.io/com/github/maniac103/rxloader/master-SNAPSHOT/rxloader-master-0.4.0-g30399e2-9.aar";
    hash = "sha256-wW6fU6deBX5XQW39qp6x6E/Kzs+rUotmE5jNM+JeHnY=";
  };

  appPackage =
    let
      androidSdk = androidSdkBuilder (s: [
        s.cmdline-tools-latest
        s.platform-tools
        s.platforms-android-36
        s.build-tools-35-0-0
        s.build-tools-36-1-0
      ]);

      gradle =
        (gradle-packages.mkGradle {
          version = "8.13";
          hash = "sha256-IPGxF2I3JUpvwgTYQ0GW+hGkz7OHVnUZxhVW6HEK7Xg=";
          defaultJava = jdk21;
        }).wrapped;
    in
    stdenv.mkDerivation (finalAttrs: {
      pname = "gh4a";
      inherit version src;

      gradleBuildTask = ":app:assembleRelease";
      gradleUpdateTask = finalAttrs.gradleBuildTask;

      mitmCache = gradle.fetchDeps {
        inherit (finalAttrs) pname;
        pkg = finalAttrs.finalPackage;
        data = ./gh4a_deps.json;
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
        ANDROID_AAPT2_FROM_MAVEN_OVERRIDE = "${androidSdk}/share/android-sdk/build-tools/36.1.0/aapt2";
      };

      postPatch = ''
        substituteInPlace app/build.gradle \
          --replace-fail \
            "    implementation 'com.github.maniac103:rxloader:master-SNAPSHOT'" \
            "    implementation files('libs/rxloader.aar')" \
          --replace-fail \
            "        buildConfigField 'String', 'CLIENT_ID', ClientId" \
            "        buildConfigField 'String', 'CLIENT_ID', (project.hasProperty('ClientId') ? ClientId : '\"0\"')" \
          --replace-fail \
            "        buildConfigField 'String', 'CLIENT_SECRET', ClientSecret" \
            "        buildConfigField 'String', 'CLIENT_SECRET', (project.hasProperty('ClientSecret') ? ClientSecret : '\"0\"')"
      '';

      preConfigure = ''
        export ANDROID_USER_HOME="$HOME/.android"
        mkdir -p "$ANDROID_USER_HOME"
        echo "sdk.dir=${androidSdk}/share/android-sdk" > local.properties
        mkdir -p app/libs
        cp ${rxloaderAar} app/libs/rxloader.aar
      '';

      gradleFlags = [
        "-Dorg.gradle.java.installations.auto-download=false"
        "-Dorg.gradle.java.installations.paths=${jdk21}"
        "-Dandroid.aapt2FromMavenOverride=${androidSdk}/share/android-sdk/build-tools/36.1.0/aapt2"
        "-Dorg.gradle.project.android.aapt2FromMavenOverride=${androidSdk}/share/android-sdk/build-tools/36.1.0/aapt2"
      ];

      installPhase = ''
        runHook preInstall
        apk_path="$(find app/build/outputs/apk/release -type f -name '*.apk' | head -n 1)"
        test -n "$apk_path" && test -f "$apk_path"
        install -Dm644 "$apk_path" "$out/gh4a.apk"
        runHook postInstall
      '';

      meta = with lib; {
        description = "GitHub for Android app built from source";
        homepage = "https://github.com/slapperwan/gh4a";
        license = licenses.asl20;
        platforms = platforms.unix;
      };
    });
in
mk-apk-package {
  inherit appPackage;
  mainApk = "gh4a.apk";
  signScriptName = "sign-gh4a";
  fdroid = {
    appId = "com.gh4a";
    metadataYml = ''
      Categories:
        - Internet
      License: Apache-2.0
      SourceCode: https://github.com/slapperwan/gh4a
      IssueTracker: https://github.com/slapperwan/gh4a/issues
      Changelog: https://github.com/slapperwan/gh4a/blob/master/CHANGES
      AutoName: OctoDroid
      Summary: GitHub client for Android
      Description: |-
        OctoDroid (gh4a) is a full-featured GitHub client for Android.
        This package builds the upstream project from source.
    '';
  };
}
