{
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
  androidSdk = androidSdkBuilder (s: [
    s.cmdline-tools-latest
    s.platform-tools
    s.platforms-android-35
    s.build-tools-35-0-0
    s.ndk-28-0-13004108
    s.cmake-3-22-1
  ]);

  gradle =
    (gradle-packages.mkGradle {
      version = "8.12.1";
      hash = "sha256-jZepeYT2y9K4X+TGCnQ0QKNHVEvxiBgEjmEfUojUbJQ=";
      defaultJava = jdk21;
    }).wrapped;

  ksudArm64 = fetchurl {
    url = "https://github.com/tiann/KernelSU/releases/download/v1.0.5/ksud-aarch64-linux-android";
    hash = "sha256-Od7Jz+fXl9vM2ZnfmTVU5RDo2zbznsOi8lxb59SDerY=";
  };

  ksudX8664 = fetchurl {
    url = "https://github.com/tiann/KernelSU/releases/download/v1.0.5/ksud-x86_64-linux-android";
    hash = "sha256-lSqct3y8R/ODGuOUoOkCVBRctfE8lCfNR09cPnntZsQ=";
  };
in
stdenv.mkDerivation (finalAttrs: {
  pname = "kernelsu";
  version = "1.0.5";

  src = fetchFromGitHub {
    owner = "tiann";
    repo = "KernelSU";
    tag = "v${finalAttrs.version}";
    hash = "sha256-UZADtLgR7F89fxVc+rxcM2A+67hm6uBSGlQ4oR/YtRA=";
  };

  sourceRoot = "source/manager";

  gradleBuildTask = ":app:assembleRelease";
  gradleUpdateTask = finalAttrs.gradleBuildTask;

  mitmCache = gradle.fetchDeps {
    inherit (finalAttrs) pname;
    pkg = finalAttrs.finalPackage;
    data = "kernelsu_deps.json";
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
    JAVA_HOME = if stdenv.isDarwin then "${jdk21}" else "${jdk21}/lib/openjdk";
    ANDROID_HOME = "${androidSdk}/share/android-sdk";
    ANDROID_SDK_ROOT = "${androidSdk}/share/android-sdk";
    ANDROID_NDK_ROOT = "${androidSdk}/share/android-sdk/ndk/28.0.13004108";
    ANDROID_AAPT2_FROM_MAVEN_OVERRIDE = "${androidSdk}/share/android-sdk/build-tools/35.0.0/aapt2";
  };

  postPatch = ''
    substituteInPlace build.gradle.kts \
      --replace-fail \
      'val managerVersionCode by extra(getVersionCode())' \
      'val managerVersionCode by extra(12081)' \
      --replace-fail \
      'val managerVersionName by extra(getVersionName())' \
      'val managerVersionName by extra("v1.0.5")'

    # TODO: replace these fetched release artifacts with ksud binaries built
    # from source in Nix, matching the upstream GitHub workflow.
    install -Dm755 ${ksudArm64} app/src/main/jniLibs/arm64-v8a/libksud.so
    install -Dm755 ${ksudX8664} app/src/main/jniLibs/x86_64/libksud.so

    printf '\norg.gradle.jvmargs=-Xmx2048m -XX:MaxMetaspaceSize=1024m\n' >> gradle.properties
  '';

  preConfigure = ''
    export ANDROID_USER_HOME="$HOME/.android"
    mkdir -p "$ANDROID_USER_HOME"
    echo "sdk.dir=${androidSdk}/share/android-sdk" > local.properties
  '';

  gradleFlags =
    let
      postfix = if stdenv.isDarwin then "" else "/lib/openjdk";
    in
    [
      "-Dorg.gradle.java.installations.auto-download=false"
      "-Dorg.gradle.java.installations.paths=${jdk21}${postfix}"
      "-Dandroid.aapt2FromMavenOverride=${androidSdk}/share/android-sdk/build-tools/35.0.0/aapt2"
      "-Dorg.gradle.project.android.aapt2FromMavenOverride=${androidSdk}/share/android-sdk/build-tools/35.0.0/aapt2"
    ];

  installPhase = ''
    runHook preInstall

    apk_path="$(find app/build/outputs/apk/release -name '*.apk' | head -n 1)"
    install -Dm644 "$apk_path" "$out/kernelsu.apk"

    runHook postInstall
  '';

  meta = with lib; {
    description = "KernelSU Manager app built from source";
    homepage = "https://github.com/tiann/KernelSU";
    license = licenses.gpl3Plus;
    platforms = platforms.unix;
  };
})
