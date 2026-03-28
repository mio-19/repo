{
  lib,
  jdk21,
  gradle-packages,
  stdenv,
  fetchFromGitHub,
  writableTmpDirAsHomeHook,
  androidSdkBuilder,
  git,
}:
let
  androidSdk = androidSdkBuilder (s: [
    s.cmdline-tools-latest
    s.platform-tools
    s.platforms-android-36
    s.build-tools-35-0-0
    s.build-tools-36-0-0
    s.ndk-27-0-12077973
    s.cmake-3-22-1
  ]);

  gradle =
    (gradle-packages.mkGradle {
      version = "8.14.3";
      hash = "sha256-vXEQIhNJMGCVbsIp2Ua+7lcVjb2J0OYrkbyg+ixfNTE=";
      defaultJava = jdk21;
    }).wrapped;
in
stdenv.mkDerivation (finalAttrs: {
  pname = "vpnhotspot";
  version = "2.19.1";

  src = fetchFromGitHub {
    owner = "Mygod";
    repo = "VPNHotspot";
    tag = "v${finalAttrs.version}";
    hash = "sha256-706n9cGGZYxB3KG7/MWbsTfICfHJpaXygihBs+MeaGA=";
  };

  patches = [ ./remove-google-services.patch ];

  gradleBuildTask = ":mobile:assembleRelease";
  gradleUpdateTask = finalAttrs.gradleBuildTask;

  mitmCache = gradle.fetchDeps {
    inherit (finalAttrs) pname;
    pkg = finalAttrs.finalPackage;
    data = ./vpnhotspot_deps.json;
    silent = false;
    useBwrap = false;
  };

  nativeBuildInputs = [
    gradle
    jdk21
    writableTmpDirAsHomeHook
    git
  ];

  env = {
    JAVA_HOME = jdk21;
    ANDROID_HOME = "${androidSdk}/share/android-sdk";
    ANDROID_SDK_ROOT = "${androidSdk}/share/android-sdk";
    ANDROID_NDK_ROOT = "${androidSdk}/share/android-sdk/ndk/27.0.12077973";
    ANDROID_AAPT2_FROM_MAVEN_OVERRIDE = "${androidSdk}/share/android-sdk/build-tools/36.0.0/aapt2";
  };

  postPatch = ''
    substituteInPlace mobile/build.gradle.kts \
      --replace-fail 'vcsInfo.include = true' 'vcsInfo.include = false'
  '';

  preConfigure = ''
    export ANDROID_USER_HOME="$HOME/.android"
    mkdir -p "$ANDROID_USER_HOME"
    echo "sdk.dir=${androidSdk}/share/android-sdk" > local.properties
  '';

  gradleFlags = [
    "-xlintVitalRelease"
    "-Dorg.gradle.java.installations.auto-download=false"
    "-Dorg.gradle.java.installations.paths=${jdk21}"
    "-Dandroid.aapt2FromMavenOverride=${androidSdk}/share/android-sdk/build-tools/36.0.0/aapt2"
    "-Dorg.gradle.project.android.aapt2FromMavenOverride=${androidSdk}/share/android-sdk/build-tools/36.0.0/aapt2"
  ];

  installPhase = ''
    runHook preInstall
    install -Dm644 mobile/build/outputs/apk/release/mobile-release-unsigned.apk "$out/vpnhotspot.apk"
    runHook postInstall
  '';

  meta = with lib; {
    description = "Android VPN tethering and hotspot helper";
    homepage = "https://github.com/Mygod/VPNHotspot";
    license = licenses.asl20;
    platforms = platforms.unix;
  };
})
