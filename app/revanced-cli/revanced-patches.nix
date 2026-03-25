{
  lib,
  stdenv,
  fetchFromGitLab,
  gradle-packages,
  jdk17,
  writableTmpDirAsHomeHook,
  androidSdkBuilder,
  revanced-patches-gradle-plugin,
  revanced-patcher-m2,
}:
let
  androidSdk = androidSdkBuilder (s: [
    s.cmdline-tools-latest
    s.platform-tools
    s.platforms-android-34
    s.platforms-android-35
    s.platforms-android-36
    s.build-tools-36-0-0
  ]);

  gradle =
    (gradle-packages.mkGradle {
      version = "9.3.1";
      hash = "sha256-smbV/2uQ6tptw7IMsJDjcxMC5VOifF0+TfHw12vq/wY=";
      defaultJava = jdk17;
    }).wrapped;
in
stdenv.mkDerivation (finalAttrs: {
  pname = "revanced-patches";
  version = "6.1.0";

  src = fetchFromGitLab {
    owner = "ReVanced";
    repo = "revanced-patches";
    rev = "v${finalAttrs.version}";
    hash = "sha256-gXvEntqX7mLlLyWVa3WRqQGNr3rDmuHn1ZqGO9Kzptg=";
  };

  gradleBuildTask = "publish";
  gradleUpdateTask = finalAttrs.gradleBuildTask;

  mitmCache = gradle.fetchDeps {
    pname = "revanced-patches";
    pkg = finalAttrs.finalPackage;
    data = ./revanced-patches_deps.json;
    silent = false;
    useBwrap = false;
  };

  nativeBuildInputs = [
    gradle
    jdk17
    writableTmpDirAsHomeHook
  ];

  env = {
    JAVA_HOME = if stdenv.isDarwin then "${jdk17}" else "${jdk17}/lib/openjdk";
    ANDROID_HOME = "${androidSdk}/share/android-sdk";
    ANDROID_SDK_ROOT = "${androidSdk}/share/android-sdk";
  };

  postUnpack = ''
    mkdir -p "$sourceRoot/.m2/repository"
    cp -a ${revanced-patches-gradle-plugin}/* "$sourceRoot/.m2/repository/"
    chmod -R u+w "$sourceRoot/.m2/repository"
    cp -a ${revanced-patcher-m2}/* "$sourceRoot/.m2/repository/"
    chmod -R u+w "$sourceRoot/.m2/repository"

    substituteInPlace "$sourceRoot/settings.gradle.kts" \
      --replace-fail '            url = uri("https://maven.pkg.github.com/revanced/revanced-patches-gradle-plugin")' \
      '            url = uri("file://" + rootDir.resolve(".m2/repository").absolutePath)'
    substituteInPlace "$sourceRoot/settings.gradle.kts" \
      --replace-fail '            credentials(PasswordCredentials::class)' ""

    substituteInPlace "$sourceRoot/patches/build.gradle.kts" \
      --replace-fail '            url = uri("https://maven.pkg.github.com/revanced/revanced-patches")' \
      '            url = uri("file://" + rootProject.projectDir.resolve("../build/m2").absolutePath)'
    substituteInPlace "$sourceRoot/patches/build.gradle.kts" \
      --replace-fail '            credentials(PasswordCredentials::class)' ""
  '';

  preConfigure = ''
    export ANDROID_USER_HOME="$HOME/.android"
    mkdir -p "$ANDROID_USER_HOME"
    echo "sdk.dir=${androidSdk}/share/android-sdk" > local.properties
  '';

  gradleFlags = [
    "-xlintVitalRelease"
    "-Dorg.gradle.java.installations.auto-download=false"
    "-Dorg.gradle.java.installations.paths=${finalAttrs.env.JAVA_HOME}"
    "-Dandroid.aapt2FromMavenOverride=${androidSdk}/share/android-sdk/build-tools/36.0.0/aapt2"
    "-Dorg.gradle.project.android.aapt2FromMavenOverride=${androidSdk}/share/android-sdk/build-tools/36.0.0/aapt2"
  ];

  installPhase = ''
    runHook preInstall
    mkdir -p "$out"
    cp -a build/m2/. "$out/"
    runHook postInstall
  '';

  meta = with lib; {
    description = "ReVanced patches built from source";
    homepage = "https://github.com/ReVanced/revanced-patches";
    license = licenses.gpl3Only;
    platforms = platforms.unix;
  };
})
