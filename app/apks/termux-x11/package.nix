{
  mk-apk-package,
  lib,
  stdenv,
  sources,
  androidSdkBuilder,
  gradle_9_5_1,
  jdk17_headless,

  writableTmpDirAsHomeHook,
  bison,
  python3,
  gcc,
}:
let
  appPackage =
    let
      rev = sources.termux_x11.version;
      shortRev = builtins.substring 0 7 rev;
      version = "unstable-${sources.termux_x11.date}";
      src = sources.termux_x11.src;

      androidSdk = androidSdkBuilder (s: [
        s.cmdline-tools-latest
        s.platform-tools
        s.platforms-android-34
        s.build-tools-34-0-0
        s.build-tools-36-0-0
        s.ndk-29-0-14206865
        s.cmake-3-31-6
      ]);

      gradle = gradle_9_5_1;
    in
    stdenv.mkDerivation (finalAttrs: {
      pname = "termux-x11";
      inherit version;
      inherit src;

      gradleBuildFlags = ":lorie-app:assembleRelease";
      gradleUpdateTask = "${finalAttrs.gradleBuildFlags} :shell-loader:stub:extractDebugAnnotations";

      mitmCache = gradle.fetchDeps {
        inherit (finalAttrs) pname;
        pkg = finalAttrs.finalPackage;
        data = ./termux-x11_deps.json;
        silent = false;
        useBwrap = false;
      };

      nativeBuildInputs = [
        gradle
        jdk17_headless

        writableTmpDirAsHomeHook
        bison
        python3
        gcc
      ];

      env = {
        JAVA_HOME = jdk17_headless.passthru.home;
        ANDROID_HOME = "${androidSdk}/share/android-sdk";
        ANDROID_SDK_ROOT = "${androidSdk}/share/android-sdk";
        ANDROID_NDK_ROOT = "${androidSdk}/share/android-sdk/ndk/29.0.14206865";
        ANDROID_AAPT2_FROM_MAVEN_OVERRIDE = "${androidSdk}/share/android-sdk/build-tools/36.0.0/aapt2";
        CURRENT_COMMIT = rev;
      };

      postPatch = ''
        substituteInPlace lorie/version.gradle \
          --replace-fail "def commit = 'git rev-parse --verify --short HEAD'.execute().text.trim()" "def commit = System.getenv('TERMUX_X11_GIT_SHORT_COMMIT') ?: '${shortRev}'" \
          --replace-fail '-''${commit.length() == 1 ? "nongit" : commit}-''${(new Date()).format("dd.MM.yy")}' '+git.''${commit}'

        substituteInPlace lorie/build.gradle \
          --replace-fail "\"\\\"\" + (\"git rev-parse HEAD\\n\".execute().getText().trim() ?: (System.getenv('CURRENT_COMMIT') ?: \"NO_COMMIT\")) + \"\\\"\"" "\"\\\"\" + (System.getenv('CURRENT_COMMIT') ?: \"${rev}\") + \"\\\"\""

        substituteInPlace shell-loader/build.gradle \
          --replace-fail "\"\\\"\" + (\"git rev-parse HEAD\\n\".execute().getText().trim() ?: (System.getenv('CURRENT_COMMIT') ?: \"NO_COMMIT\")) + \"\\\"\"" "\"\\\"\" + (System.getenv('CURRENT_COMMIT') ?: \"${rev}\") + \"\\\"\"" \
          --replace-fail "apply from: 'companion-package.gradle'" "// companion packages not needed for APK build"

        substituteInPlace lorie-app/build.gradle \
          --replace-fail "tasks.matching { it.name == 'assembleDebug' }.configureEach { dependsOn ':shell-loader:buildCompanionPackage' }" "// companion packages not needed for APK build"

        substituteInPlace lorie/src/main/cpp/recipes/xkbcomp.cmake \
          --replace-fail 'COMMAND "/usr/bin/gcc"' 'COMMAND "${gcc}/bin/gcc"'
      '';

      preConfigure = ''
        export ANDROID_USER_HOME="$HOME/.android"
        mkdir -p "$ANDROID_USER_HOME"
        echo "sdk.dir=${androidSdk}/share/android-sdk" > local.properties
        echo "cmake.dir=${androidSdk}/share/android-sdk/cmake/3.31.6" >> local.properties
      '';

      gradleFlags = [
        "-xlintVitalRelease"
        "-Dorg.gradle.java.installations.auto-download=false"
        "-Dorg.gradle.java.installations.paths=${finalAttrs.env.JAVA_HOME}"
        "-Dandroid.aapt2FromMavenOverride=${androidSdk}/share/android-sdk/build-tools/36.0.0/aapt2"
        "-Dorg.gradle.project.android.aapt2FromMavenOverride=${androidSdk}/share/android-sdk/build-tools/36.0.0/aapt2"
        "-Dorg.gradle.jvmargs=-Xmx4096m"
      ];

      TERMUX_X11_GIT_SHORT_COMMIT = shortRev;

      installPhase = ''
        runHook preInstall
        apk_path="$(find lorie-app -name "*.apk" | grep -v unaligned | head -n 1)"
        if [ -z "$apk_path" ]; then
          echo "Failed to find APK!"
          find . -name "*.apk"
          exit 1
        fi
        install -Dm644 "$apk_path" "$out/termux-x11.apk"
        runHook postInstall
      '';

      meta = with lib; {
        description = "Termux X11 server add-on app built from source";
        homepage = "https://github.com/termux/termux-x11";
        license = licenses.gpl3Only;
        platforms = platforms.linux;
      };
    });
in
mk-apk-package {
  inherit appPackage;
  mainApk = "termux-x11.apk";
  signScriptName = "sign-termux-x11";
  fdroid = {
    appId = "com.termux.x11";
    metadataYml = ''
      Categories:
        - Development
      License: GPL-3.0-only
      WebSite: https://termux.com
      SourceCode: https://github.com/termux/termux-x11
      IssueTracker: https://github.com/termux/termux-x11/issues
      Changelog: https://github.com/termux/termux-x11/releases/tag/nightly
      Donate: https://termux.com/donate.html
      OpenCollective: Termux
      AutoName: Termux:X11
      Summary: X11 server add-on for Termux
      Description: |-
        Termux:X11 is the X11 server companion app for Termux.
        This package is built from source from the upstream master
        branch at commit ${sources.termux_x11.version}.

        F-Droid does not currently ship metadata for this application,
        so this repo follows the upstream nightly debug universal APK
        build layout instead.
    '';
  };
}
