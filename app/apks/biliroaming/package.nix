{
  lib,
  stdenv,
  fetchFromGitHub,
  gradle_8_12,
  androidSdkBuilder,
  jdk21_headless,
  writableTmpDirAsHomeHook,
  fetchpatch,
}:
let
  version = "unstable-2026-03-17";

  androidSdk = androidSdkBuilder (s: [
    s.cmdline-tools-latest
    s.platform-tools
    s.platforms-android-35
    s.build-tools-35-0-0
    s.ndk-29-0-14206865
    s.cmake-4-1-2
  ]);
  gradle = gradle_8_12;

  androidSdkRoot = "${androidSdk}/share/android-sdk";
  aapt2Path = "${androidSdkRoot}/build-tools/35.0.0/aapt2";
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

  patches = [
    (fetchpatch {
      name = "skip ad";
      url = "https://github.com/yujincheng08/BiliRoaming/pull/1701.patch";
      hash = "sha256-295vl53oiZfqS+CdAZSwHl/yv4d4uC5vcrhv0oCZBxg=";
    })
  ];

  postUnpack = ''
    substituteInPlace "$sourceRoot/app/build.gradle.kts" \
      --replace-fail \
        'val appVerCode = jgit.repo()?.commitCount("refs/remotes/origin/master") ?: 0' \
        'val appVerCode = jgit.repo()?.commitCount("refs/remotes/origin/master") ?: 1'
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
    jdk21_headless
    writableTmpDirAsHomeHook
  ];

  env = {
    JAVA_HOME = jdk21_headless.passthru.home;
    ANDROID_HOME = androidSdkRoot;
    ANDROID_SDK_ROOT = androidSdkRoot;
    ANDROID_NDK_ROOT = "${androidSdkRoot}/ndk/29.0.14206865";
    ANDROID_AAPT2_FROM_MAVEN_OVERRIDE = aapt2Path;
  };

  preConfigure = ''
    export ANDROID_USER_HOME="$HOME/.android"
    export GRADLE_USER_HOME="$HOME/.gradle"
    mkdir -p "$ANDROID_USER_HOME" "$GRADLE_USER_HOME"

    echo "org.gradle.jvmargs=-Xmx4g -XX:MaxMetaspaceSize=1g" >> gradle.properties
  '';

  gradleFlags = [
    "--no-daemon"
    "-Dorg.gradle.java.installations.auto-download=false"
    "-Dorg.gradle.java.installations.paths=${jdk21_headless.passthru.home}"
    "-Dandroid.aapt2FromMavenOverride=${aapt2Path}"
    "-Dorg.gradle.project.android.aapt2FromMavenOverride=${aapt2Path}"
  ];

  installPhase = ''
    runHook preInstall
    mkdir -p "$out"
    mv app/build/outputs/apk/release/app-release-unsigned.apk "$out/biliroaming.apk"
    runHook postInstall
  '';

  meta = with lib; {
    description = "BiliRoaming Xposed module built from the latest commit";
    homepage = "https://github.com/yujincheng08/BiliRoaming";
    license = licenses.gpl3Only;
    platforms = platforms.unix;
  };
})
