{
  lib,
  stdenv,
  fetchFromGitHub,
  gradle-packages,
  androidSdkBuilder,
  jdk21,
  writableTmpDirAsHomeHook,
}:
let
  version = "1.6.13";

  androidSdk = androidSdkBuilder (s: [
    s.cmdline-tools-latest
    s.platform-tools
    s.platforms-android-35
    s.build-tools-35-0-0
    s.ndk-29-0-14206865
    s.cmake-4-1-2
  ]);
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
    jdk21
    writableTmpDirAsHomeHook
  ];

  env = {
    JAVA_HOME = jdk21;
    ANDROID_HOME = "${androidSdk}/share/android-sdk";
    ANDROID_SDK_ROOT = "${androidSdk}/share/android-sdk";
    ANDROID_NDK_ROOT = "${androidSdk}/share/android-sdk/ndk/29.0.14206865";
    ANDROID_AAPT2_FROM_MAVEN_OVERRIDE = "${androidSdk}/share/android-sdk/build-tools/35.0.0/aapt2";
  };

  preConfigure = ''
    export ANDROID_USER_HOME="$PWD/.android"
    export GRADLE_USER_HOME="$PWD/.gradle"
    mkdir -p "$ANDROID_USER_HOME" "$GRADLE_USER_HOME"

    cat >> gradle.properties <<EOF
    org.gradle.jvmargs=-Xmx4g -XX:MaxMetaspaceSize=1g
    EOF
  '';

  gradleFlags = [
    "--no-daemon"
    "-Dorg.gradle.java.installations.auto-download=false"
    "-Dorg.gradle.java.installations.paths=${jdk21}"
    "-Dandroid.aapt2FromMavenOverride=${androidSdk}/share/android-sdk/build-tools/35.0.0/aapt2"
    "-Dorg.gradle.project.android.aapt2FromMavenOverride=${androidSdk}/share/android-sdk/build-tools/35.0.0/aapt2"
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
