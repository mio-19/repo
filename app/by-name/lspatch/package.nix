{
  lib,
  stdenv,
  fetchFromGitHub,
  gradle-packages,
  androidSdkBuilder,
  jdk21_headless,
  makeWrapper,
  jre_headless,
  writableTmpDirAsHomeHook,
  runCommand,
  gradle_9,
  git,
}:
let
  version = "0.8-unstable-20260330";

  androidSdk = androidSdkBuilder (s: [
    s.cmdline-tools-latest
    s.platform-tools
    s.platforms-android-36
    s.platforms-android-37-0
    s.build-tools-36-0-0
    s.build-tools-37-0-0
    # Tried NDK 29.0.14206865 here, but LSPatch then failed in native x86
    # lsplant builds with duplicate SSE intrinsic definitions under Clang 21,
    # so this stays on the baseline NDK for now.
    s.ndk-29-0-13113456
    s.cmake-3-31-6
  ]);

  gradle = gradle_9;

  common = stdenv.mkDerivation (finalAttrs: {
    pname = "lspatch";
    inherit version;

    src = fetchFromGitHub {
      owner = "JingMatrix";
      repo = "LSPatch";
      rev = "0dc50f4";
      fetchSubmodules = true;
      hash = "sha256-h4BfJai0HcZTFdn01M9l9lqWBFLIuyy8Rw2VgfL8R38=";
    };

    patches = [
      ./build-gradle-fixed-version.patch
    ];

    postPatch = ''
      substituteInPlace core/build.gradle.kts \
        --replace-fail 'val androidCompileNdkVersion = "29.0.14206865"' 'val androidCompileNdkVersion = "29.0.13113456"'
    '';

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
      git
      gradle
      jdk21_headless
      writableTmpDirAsHomeHook
    ];

    env = {
      JAVA_HOME = jdk21_headless;
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
      "-Dorg.gradle.java.installations.paths=${jdk21_headless}"
      "-Dandroid.aapt2FromMavenOverride=${androidSdk}/share/android-sdk/build-tools/36.0.0/aapt2"
      "-Dorg.gradle.project.android.aapt2FromMavenOverride=${androidSdk}/share/android-sdk/build-tools/36.0.0/aapt2"
    ];

    installPhase = ''
      runHook preInstall

      jar_path="$(echo out/release/lspatch-v*-release.jar | awk '{print $1}')"
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
        makeWrapper ${lib.getExe jre_headless} "$out/bin/lspatch" --add-flags -jar --add-flags "${common}/lspatch.jar"
      '';

  manager = runCommand "lspatch-manager-${version}" { } ''
    install -Dm644 "${common}/lspatch-manager.apk" "$out/lspatch-manager.apk"
  '';
}
