{
  lib,
  stdenv,
  fetchFromGitHub,
  gradle-packages,
  androidSdkBuilder,
  jdk25,
  makeWrapper,
  jre,
  writableTmpDirAsHomeHook,
  runCommand,
  fetchpatch,
}:
let
  version = "0.8-unstable-20260330";

  androidSdk = androidSdkBuilder (s: [
    s.cmdline-tools-latest
    s.platform-tools
    s.platforms-android-36
    s.build-tools-36-0-0
    # Tried NDK 29.0.14206865 here, but LSPatch then failed in native x86
    # lsplant builds with duplicate SSE intrinsic definitions under Clang 21,
    # so this stays on the baseline NDK for now.
    s.ndk-29-0-13113456
    s.cmake-3-31-6
  ]);

  gradle =
    (gradle-packages.mkGradle {
      version = "8.13";
      hash = "sha256-IPGxF2I3JUpvwgTYQ0GW+hGkz7OHVnUZxhVW6HEK7Xg=";
      defaultJava = jdk25;
    }).wrapped;

  common = stdenv.mkDerivation (finalAttrs: {
    pname = "lspatch";
    inherit version;

    src = fetchFromGitHub {
      owner = "JingMatrix";
      repo = "LSPatch";
      rev = "ae8b908305a348ec80f7900599c2dab30d56f901";
      fetchSubmodules = true;
      hash = "sha256-pM2E5Rgjrj1/ajGeCghCsnTaeEErjx+ExjCRSfeFjCk=";
    };

    patches = [
      ./build-gradle-fixed-version.patch
      ./build-gradle-disable-cxx-modules.patch
      (fetchpatch {
        name = "[translation] Update translation from Crowdin";
        url = "https://github.com/JingMatrix/LSPatch/pull/57.patch";
        hash = "sha256-9j4d+mtZrnRSs6wkqYixbfRXhmpMwenyfa4MARKRM8M=";
      })
    ];

    gradleBuildTask = "buildRelease";
    gradleUpdateTask = finalAttrs.gradleBuildTask;

    mitmCache = gradle.fetchDeps {
      inherit (finalAttrs) pname;
      pkg = finalAttrs.finalPackage;
      data = ./lspatch_deps.json;
      silent = false;
      useBwrap = false;
    };

    nativeBuildInputs = [
      gradle
      jdk25
      writableTmpDirAsHomeHook
    ];

    env = {
      JAVA_HOME = jdk25;
      ANDROID_HOME = "${androidSdk}/share/android-sdk";
      ANDROID_SDK_ROOT = "${androidSdk}/share/android-sdk";
      ANDROID_NDK_ROOT = "${androidSdk}/share/android-sdk/ndk/29.0.13113456";
      ANDROID_AAPT2_FROM_MAVEN_OVERRIDE = "${androidSdk}/share/android-sdk/build-tools/36.0.0/aapt2";
    };

    preConfigure = ''
      export ANDROID_USER_HOME="$PWD/.android"
      export GRADLE_USER_HOME="$PWD/.gradle"
      mkdir -p "$ANDROID_USER_HOME" "$GRADLE_USER_HOME"

      echo "sdk.dir=$ANDROID_HOME" > local.properties
      cat >> gradle.properties <<EOF
      org.gradle.jvmargs=-Xmx4g -XX:MaxMetaspaceSize=1g
      android.aapt2FromMavenOverride=$ANDROID_HOME/build-tools/36.0.0/aapt2
      org.gradle.project.android.aapt2FromMavenOverride=$ANDROID_HOME/build-tools/36.0.0/aapt2
      EOF
    '';

    gradleFlags = [
      "-xlintVitalRelease"
      "--no-daemon"
      "-Dorg.gradle.java.installations.auto-download=false"
      "-Dorg.gradle.java.installations.paths=${jdk25}"
      "-Dandroid.aapt2FromMavenOverride=${androidSdk}/share/android-sdk/build-tools/36.0.0/aapt2"
      "-Dorg.gradle.project.android.aapt2FromMavenOverride=${androidSdk}/share/android-sdk/build-tools/36.0.0/aapt2"
    ];

    installPhase = ''
      runHook preInstall

      jar_path="$(echo out/release/jar-v*-release.jar | awk '{print $1}')"
      apk_path="$(echo out/release/manager-v*-release.apk | awk '{print $1}')"

      install -Dm644 "$jar_path" "$out/lspatch.jar"
      install -Dm644 "$apk_path" "$out/lspatch-manager.apk"

      runHook postInstall
    '';

    meta = with lib; {
      description = "LSPatch CLI and manager app built from source";
      homepage = "https://github.com/JingMatrix/LSPatch";
      license = licenses.gpl3Only;
      platforms = platforms.unix;
    };
  });
in
{
  inherit common;

  cli =
    runCommand "lspatch-cli-${version}"
      {
        nativeBuildInputs = [ makeWrapper ];
        meta = with lib; {
          description = "LSPatch CLI";
          homepage = "https://github.com/JingMatrix/LSPatch";
          license = licenses.gpl3Only;
          platforms = platforms.unix;
          mainProgram = "lspatch";
        };
      }
      ''
        mkdir -p $out/bin
        makeWrapper ${lib.getExe jre} "$out/bin/lspatch" --add-flags -jar --add-flags "${common}/lspatch.jar"
      '';

  manager = runCommand "lspatch-manager-${version}" { } ''
    install -Dm644 "${common}/lspatch-manager.apk" "$out/lspatch-manager.apk"
  '';
}
