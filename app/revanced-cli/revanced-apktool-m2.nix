{
  lib,
  stdenv,
  fetchFromGitHub,
  gradle-packages,
  jdk21,
  writableTmpDirAsHomeHook,
  androidSdkBuilder,
}:
let
  androidSdk = androidSdkBuilder (s: [
    s.cmdline-tools-latest
    s.platform-tools
    s.platforms-android-33
    s.build-tools-35-0-0
  ]);

  gradle =
    (gradle-packages.mkGradle {
      version = "8.7";
      hash = "sha256-VEw11r2Emuil7QvOo5umd9xA9J330YNVYVgtogCblh0=";
      defaultJava = jdk21;
    }).wrapped;
in
stdenv.mkDerivation (finalAttrs: {
  pname = "revanced-apktool-m2";
  version = "2.10.1.1";

  src = fetchFromGitHub {
    owner = "ReVanced";
    repo = "Apktool";
    rev = "49eeed6d0903a15f45600261dc528ad3414043a8";
    hash = "sha256-y9M8Vbs1Lig97OXEuqATrr2+Pidzjw73TgCT1N/lV4U=";
  };

  gradleBuildTask = "release publish";
  gradleUpdateTask = finalAttrs.gradleBuildTask;

  mitmCache = gradle.fetchDeps {
    pname = "revanced-apktool";
    pkg = finalAttrs.finalPackage;
    data = ./revanced-apktool_deps.json;
    silent = false;
    useBwrap = false;
  };

  nativeBuildInputs = [
    gradle
    jdk21
    writableTmpDirAsHomeHook
  ];

  env = {
    JAVA_HOME = if stdenv.isDarwin then "${jdk21}" else "${jdk21}/lib/openjdk";
    ANDROID_HOME = "${androidSdk}/share/android-sdk";
    ANDROID_SDK_ROOT = "${androidSdk}/share/android-sdk";
  };

  postUnpack = ''
    patch -d "$sourceRoot" -p0 < ${./revanced-apktool-build.patch}
  '';

  gradleFlags = [
    "-Dorg.gradle.java.installations.auto-download=false"
    "-Dorg.gradle.java.installations.paths=${finalAttrs.env.JAVA_HOME}"
  ];

  installPhase = ''
    runHook preInstall
    mkdir -p "$out"
    cp -a "$HOME/.m2/repository/." "$out/"
    runHook postInstall
  '';

  meta = with lib; {
    description = "ReVanced Apktool artifacts published to a local Maven repository";
    homepage = "https://github.com/ReVanced/Apktool";
    license = licenses.asl20;
    platforms = platforms.unix;
  };
})
