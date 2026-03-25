{
  lib,
  stdenv,
  fetchFromGitHub,
  gradle-packages,
  androidSdkBuilder,
  jdk21,
  ninja,
  writableTmpDirAsHomeHook,
  runCommand,
}:
let
  version = "0.8";

  androidSdk = androidSdkBuilder (s: [
    s.cmdline-tools-latest
    s.platform-tools
    s.platforms-android-36
    s.build-tools-36-0-0
    s.ndk-29-0-13113456
    s.cmake-3-31-1
  ]);

  androidSdkForBuild = runCommand "lspatch-android-sdk" { } ''
    mkdir -p "$out/share/android-sdk"
    for entry in ${androidSdk}/share/android-sdk/*; do
      name="$(basename "$entry")"
      if [ "$name" != "cmake" ]; then
        ln -s "$entry" "$out/share/android-sdk/$name"
      fi
    done

    mkdir -p "$out/share/android-sdk/cmake"
    for entry in ${androidSdk}/share/android-sdk/cmake/*; do
      name="$(basename "$entry")"
      if [ "$name" != "3.31.1" ]; then
        ln -s "$entry" "$out/share/android-sdk/cmake/$name"
      fi
    done

    mkdir -p "$out/share/android-sdk/cmake/3.31.1"
    for entry in ${androidSdk}/share/android-sdk/cmake/3.31.1/*; do
      name="$(basename "$entry")"
      if [ "$name" != "bin" ]; then
        ln -s "$entry" "$out/share/android-sdk/cmake/3.31.1/$name"
      fi
    done

    mkdir -p "$out/share/android-sdk/cmake/3.31.1/bin"
    for entry in ${androidSdk}/share/android-sdk/cmake/3.31.1/bin/*; do
      name="$(basename "$entry")"
      if [ "$name" != "ninja" ]; then
        ln -s "$entry" "$out/share/android-sdk/cmake/3.31.1/bin/$name"
      fi
    done
    ln -s ${ninja}/bin/ninja "$out/share/android-sdk/cmake/3.31.1/bin/ninja"
  '';

  gradle =
    (gradle-packages.mkGradle {
      version = "8.13";
      hash = "sha256-IPGxF2I3JUpvwgTYQ0GW+hGkz7OHVnUZxhVW6HEK7Xg=";
      defaultJava = jdk21;
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
    ];

    gradleBuildTask = "buildRelease";
    gradleUpdateTask = finalAttrs.gradleBuildTask;

    mitmCache = gradle.fetchDeps {
      inherit (finalAttrs) pname;
      pkg = finalAttrs.finalPackage;
      data = "lspatch_deps.json";
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
      ANDROID_HOME = "${androidSdkForBuild}/share/android-sdk";
      ANDROID_SDK_ROOT = "${androidSdkForBuild}/share/android-sdk";
      ANDROID_NDK_ROOT = "${androidSdkForBuild}/share/android-sdk/ndk/29.0.13113456";
      ANDROID_AAPT2_FROM_MAVEN_OVERRIDE = "${androidSdkForBuild}/share/android-sdk/build-tools/36.0.0/aapt2";
      ANDROID_USER_HOME = "$(pwd)/.android";
      GRADLE_USER_HOME = "$(pwd)/.gradle";
    };

    preConfigure = ''
      export ANDROID_USER_HOME="$PWD/.android"
      export GRADLE_USER_HOME="$PWD/.gradle"
      mkdir -p "$ANDROID_USER_HOME" "$GRADLE_USER_HOME"

      sdkRoot="$PWD/android-sdk"
      mkdir -p "$sdkRoot/build-tools" "$sdkRoot/platforms" "$sdkRoot/ndk" "$sdkRoot/cmake"
      cp -a "${androidSdkForBuild}/share/android-sdk/build-tools/36.0.0" "$sdkRoot/build-tools/"
      cp -a "${androidSdkForBuild}/share/android-sdk/cmake/3.31.1" "$sdkRoot/cmake/"
      ln -s "${androidSdkForBuild}/share/android-sdk/platforms/android-36" "$sdkRoot/platforms/android-36"
      ln -s "${androidSdkForBuild}/share/android-sdk/platform-tools" "$sdkRoot/platform-tools"
      ln -s "${androidSdkForBuild}/share/android-sdk/ndk/29.0.13113456" "$sdkRoot/ndk/29.0.13113456"
      cp -a "${androidSdkForBuild}/share/android-sdk/licenses" "$sdkRoot/"

      export ANDROID_HOME="$sdkRoot"
      export ANDROID_SDK_ROOT="$sdkRoot"
      export ANDROID_NDK_ROOT="$sdkRoot/ndk/29.0.13113456"
      export ANDROID_AAPT2_FROM_MAVEN_OVERRIDE="$sdkRoot/build-tools/36.0.0/aapt2"

      echo "sdk.dir=$sdkRoot" > local.properties
      cat >> gradle.properties <<EOF
      org.gradle.jvmargs=-Xmx4g -XX:MaxMetaspaceSize=1g
      android.aapt2FromMavenOverride=$sdkRoot/build-tools/36.0.0/aapt2
      org.gradle.project.android.aapt2FromMavenOverride=$sdkRoot/build-tools/36.0.0/aapt2
      EOF
    '';

    gradleFlags = [
    "-xlintVitalRelease"
      "--no-daemon"
      "-Dorg.gradle.java.installations.auto-download=false"
      "-Dorg.gradle.java.installations.paths=${jdk21}"
      "-Dandroid.aapt2FromMavenOverride=${androidSdkForBuild}/share/android-sdk/build-tools/36.0.0/aapt2"
      "-Dorg.gradle.project.android.aapt2FromMavenOverride=${androidSdkForBuild}/share/android-sdk/build-tools/36.0.0/aapt2"
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

  cli = runCommand "lspatch-cli-${version}" { } ''
    install -Dm644 "${common}/lspatch.jar" "$out/lspatch.jar"
  '';

  manager = runCommand "lspatch-manager-${version}" { } ''
    install -Dm644 "${common}/lspatch-manager.apk" "$out/lspatch-manager.apk"
  '';
}
