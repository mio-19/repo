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
  version = "1.6.13";

  androidSdk = androidSdkBuilder (s: [
    s.cmdline-tools-latest
    s.platform-tools
    s.platforms-android-35
    s.build-tools-35-0-0
    s.ndk-29-0-14206865
    s.cmake-3-31-1
  ]);

  androidSdkForBuild = runCommand "biliroaming-android-sdk" { } ''
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
      version = "8.12";
      hash = "sha256-egDVH7kxR4Gaq3YCT+7OILa4TkIGlBAfJ2vpUuCL7wM=";
      defaultJava = jdk21;
    }).wrapped;
in
stdenv.mkDerivation (finalAttrs: {
  pname = "biliroaming";
  inherit version;

  src = fetchFromGitHub {
    owner = "yujincheng08";
    repo = "BiliRoaming";
    rev = "b0fd682058c3f6826186b030a7d12a3acb4aa029";
    hash = "sha256-k6T5sGStxmvS0jj+ZI4N47C/DdWa9pPOtMHK7oNdN44=";
    fetchSubmodules = true;
    gitConfigFile = lib.toFile "gitconfig" ''
      [url "https://github.com/"]
        insteadOf = git@github.com:
    '';
  };

  postUnpack = ''
    cat >> "$sourceRoot/app/build.gradle.kts" <<'EOF'
    tasks.register("lintVitalRelease")
    tasks.register("lintVitalDebug")
    EOF
    substituteInPlace "$sourceRoot/app/build.gradle.kts" \
      --replace-fail \
        'val appVerCode = jgit.repo()?.commitCount("refs/remotes/origin/master") ?: 0' \
        'val appVerCode = jgit.repo()?.commitCount("refs/remotes/origin/master") ?: 1' \
      --replace-fail \
        'version = "4.1.0+"' \
        'version = "3.31.1"'
  '';

  gradleBuildTask = ":app:assembleRelease";
  gradleUpdateTask = finalAttrs.gradleBuildTask;

  mitmCache = gradle.fetchDeps {
    inherit (finalAttrs) pname;
    pkg = finalAttrs.finalPackage;
    data = ./biliroaming_deps.json;
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
    ANDROID_NDK_ROOT = "${androidSdkForBuild}/share/android-sdk/ndk/29.0.14206865";
    ANDROID_AAPT2_FROM_MAVEN_OVERRIDE = "${androidSdkForBuild}/share/android-sdk/build-tools/35.0.0/aapt2";
    ANDROID_USER_HOME = "$(pwd)/.android";
    GRADLE_USER_HOME = "$(pwd)/.gradle";
  };

  preConfigure = ''
    export ANDROID_USER_HOME="$PWD/.android"
    export GRADLE_USER_HOME="$PWD/.gradle"
    mkdir -p "$ANDROID_USER_HOME" "$GRADLE_USER_HOME"

    sdkRoot="$PWD/android-sdk"
    mkdir -p "$sdkRoot/build-tools" "$sdkRoot/platforms" "$sdkRoot/ndk" "$sdkRoot/cmake"
    cp -a "${androidSdkForBuild}/share/android-sdk/build-tools/35.0.0" "$sdkRoot/build-tools/"
    cp -a "${androidSdkForBuild}/share/android-sdk/cmake/3.31.1" "$sdkRoot/cmake/"
    ln -s "${androidSdkForBuild}/share/android-sdk/platforms/android-35" "$sdkRoot/platforms/android-35"
    ln -s "${androidSdkForBuild}/share/android-sdk/platform-tools" "$sdkRoot/platform-tools"
    ln -s "${androidSdkForBuild}/share/android-sdk/ndk/29.0.14206865" "$sdkRoot/ndk/29.0.14206865"
    cp -a "${androidSdkForBuild}/share/android-sdk/licenses" "$sdkRoot/"

    export ANDROID_HOME="$sdkRoot"
    export ANDROID_SDK_ROOT="$sdkRoot"
    export ANDROID_NDK_ROOT="$sdkRoot/ndk/29.0.14206865"
    export ANDROID_AAPT2_FROM_MAVEN_OVERRIDE="$sdkRoot/build-tools/35.0.0/aapt2"

    echo "sdk.dir=$sdkRoot" > local.properties
    cat >> gradle.properties <<EOF
    org.gradle.jvmargs=-Xmx4g -XX:MaxMetaspaceSize=1g
    android.aapt2FromMavenOverride=$sdkRoot/build-tools/35.0.0/aapt2
    org.gradle.project.android.aapt2FromMavenOverride=$sdkRoot/build-tools/35.0.0/aapt2
    EOF
  '';

  gradleFlags = [
    "--no-daemon"
    "-x"
    "lintVitalRelease"
    "-Dorg.gradle.java.installations.auto-download=false"
    "-Dorg.gradle.java.installations.paths=${jdk21}"
    "-Dandroid.aapt2FromMavenOverride=${androidSdkForBuild}/share/android-sdk/build-tools/35.0.0/aapt2"
    "-Dorg.gradle.project.android.aapt2FromMavenOverride=${androidSdkForBuild}/share/android-sdk/build-tools/35.0.0/aapt2"
  ];

  installPhase = ''
    runHook preInstall
    apk_path="$(find app/build -name 'BiliRoaming_*.apk' -print -quit)"
    if [ -z "$apk_path" ]; then
      apk_path="$(find app/build -name 'app-release.apk' -print -quit)"
    fi
    test -n "$apk_path"
    install -Dm644 "$apk_path" "$out/biliroaming.apk"
    runHook postInstall
  '';

  meta = with lib; {
    description = "BiliRoaming Xposed module built from the latest commit";
    homepage = "https://github.com/yujincheng08/BiliRoaming";
    license = licenses.gpl3Only;
    platforms = platforms.unix;
  };
})
