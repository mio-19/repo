{
  mk-apk-package,
  lib,
  jdk17_headless,
  jdk25_headless,
  gradle_9,
  stdenv,
  buildGradlePackage,
  fetchFromGitHub,
  writableTmpDirAsHomeHook,
  androidSdkBuilder,
}:
let
  appPackage =
    let
      androidSdk = androidSdkBuilder (s: [
        s.cmdline-tools-latest
        s.platform-tools
        s."platforms-android-37-0"
        s."build-tools-37-0-0"
        s."build-tools-36-0-0"
      ]);

      gradle = gradle_9;
    in
    buildGradlePackage (finalAttrs: {
      pname = "pipepipe";
      version = "5.4.0";

      src = stdenv.mkDerivation {
        name = "pipepipe-src";
        src = fetchFromGitHub {
          owner = "InfinityLoop1308";
          repo = "PipePipe";
          tag = "v\${finalAttrs.version}";
          hash = "sha256-MgX5D2d8M+xTFflOxSMpk13WXp1FOAFI7lsW8JbFwgI=";
        };
        clientSrc = fetchFromGitHub {
          owner = "InfinityLoop1308";
          repo = "PipePipeClient";
          rev = "c2a166f7df05e5ace4c80fb3e3fd27702cfc3e56";
          hash = "sha256-d1mtBzJUGoiefg+yijEeOUnO7s+4aLUqWPG1k0P3ttQ=";
        };
        extractorSrc = fetchFromGitHub {
          owner = "InfinityLoop1308";
          repo = "PipePipeExtractor";
          rev = "c68e10e2e97495877832d8df6cbac55478083019";
          hash = "sha256-6mtjoyOBK5C7qIvIuR4DjJAT+VIqGNCequzJoR4JPxk=";
        };
        installPhase = ''
          cp -r $clientSrc $out
          chmod -R +w $out
          mkdir -p $out/PipePipeExtractor
          cp -r $extractorSrc/* $out/PipePipeExtractor/
          substituteInPlace $out/settings.gradle \
            --replace-fail "includeBuild('../PipePipeExtractor')" "includeBuild('./PipePipeExtractor')" \
            --replace-warn "id 'org.gradle.toolchains.foojay-resolver-convention' version '1.0.0'" ""
        '';
      };

      gradleBuildFlags = [ ":app:assembleRelease" ];
      lockFile = ./gradle.lock;
      buildJdk = jdk25_headless;
      nativeBuildInputs = [
        gradle
        jdk17_headless
        jdk25_headless
        writableTmpDirAsHomeHook
      ];

      env = {
        JAVA_HOME = jdk25_headless;
        ANDROID_HOME = "${androidSdk}/share/android-sdk";
        ANDROID_SDK_ROOT = "${androidSdk}/share/android-sdk";
        ANDROID_AAPT2_FROM_MAVEN_OVERRIDE = "${androidSdk}/share/android-sdk/build-tools/37.0.0/aapt2";
      };

      gradleFlags = [
        "-Dandroid.builder.sdkDownload=false"
        "-Dorg.gradle.java.home=${jdk25_headless.passthru.home}"
        "-Dorg.gradle.java.installations.auto-download=false"
        "-Dorg.gradle.java.installations.paths=${jdk17_headless.passthru.home},${jdk25_headless.passthru.home}"
        "-Dandroid.aapt2FromMavenOverride=${androidSdk}/share/android-sdk/build-tools/37.0.0/aapt2"
        "-Dorg.gradle.project.android.aapt2FromMavenOverride=${androidSdk}/share/android-sdk/build-tools/37.0.0/aapt2"
      ];

      preBuild = lib.optionalString stdenv.hostPlatform.isDarwin ''
        export HOME="$TMPDIR/home"
        mkdir -p "$HOME"
        export ANDROID_USER_HOME="$HOME/.android"
        export GRADLE_USER_HOME="$HOME/.gradle"
        mkdir -p "$ANDROID_USER_HOME" "$GRADLE_USER_HOME"
        export GRADLE_OPTS="''${GRADLE_OPTS:+$GRADLE_OPTS }-Duser.home=$HOME"
      '';

      installPhase = ''
        runHook preInstall
        apk_dir="app/build/outputs/apk/release"
        apk_name="$(sed -n 's/.*"outputFile"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' "$apk_dir/output-metadata.json" | head -n 1)"
        test -n "$apk_name"
        apk_path="$apk_dir/$apk_name"
        test -f "$apk_path"
        install -Dm644 "$apk_path" "$out/pipepipe.apk"
        runHook postInstall
      '';

      passthru = {
        androidSdk = androidSdk;
      };

      meta = with lib; {
        description = "PipePipe";
        homepage = "https://github.com/InfinityLoop1308/PipePipe";
        license = licenses.gpl3Plus;
        platforms = platforms.unix;
      };
    });
in
mk-apk-package {
  inherit appPackage;
  mainApk = "pipepipe.apk";
  signScriptName = "sign-pipepipe";
  fdroid = {
    appId = "Bili.Copied";
    metadataYml = ''
      Categories:
        - Multimedia
      License: GPL-3.0-or-later
      SourceCode: https://github.com/InfinityLoop1308/PipePipe
      IssueTracker: https://github.com/InfinityLoop1308/PipePipe/issues
      Changelog: https://github.com/InfinityLoop1308/PipePipe/releases
      AutoName: PipePipe
      Summary: A FLOSS Android app to let you browse YouTube, NicoNico and BiliBili ad-free.
      Description: |-
        PipePipe is a FLOSS Android app to let you browse YouTube, NicoNico and BiliBili ad-free.
    '';
  };
}
