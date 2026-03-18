{
  lib,
  jdk21,
  gradle-packages,
  stdenv,
  src,
  version,
  apksigner,
  writableTmpDirAsHomeHook,
  androidSdkBuilder,
}:
let
  androidSdk = androidSdkBuilder (s: [
    s.cmdline-tools-latest
    s.platform-tools
    s.platforms-android-36
    s.build-tools-35-0-0
    s.build-tools-36-0-0
  ]);

  gradle =
    (gradle-packages.mkGradle {
      version = "9.1.0";
      hash = "sha256-oX3dhaJran9d23H/iwX8UQTAICxuZHgkKXkMkzaGyAY=";
      defaultJava = jdk21;
    }).wrapped;
in
stdenv.mkDerivation (finalAttrs: {
  pname = "glimpse";
  inherit version src;

  gradleBuildTask = ":app:assembleRelease";
  gradleUpdateTask = finalAttrs.gradleBuildTask;

  mitmCache = gradle.fetchDeps {
    inherit (finalAttrs) pname;
    pkg = finalAttrs.finalPackage;
    data = "glimpse_deps.json";
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
    JAVA_HOME = jdk21;
    ANDROID_HOME = "${androidSdk}/share/android-sdk";
    ANDROID_SDK_ROOT = "${androidSdk}/share/android-sdk";
    ANDROID_AAPT2_FROM_MAVEN_OVERRIDE = "${androidSdk}/share/android-sdk/build-tools/35.0.0/aapt2";
  };

  preConfigure = ''
    export ANDROID_USER_HOME="$HOME/.android"
    mkdir -p "$ANDROID_USER_HOME"
    echo "sdk.dir=${androidSdk}/share/android-sdk" > local.properties
  '';

  gradleFlags = [
    "-Dorg.gradle.java.installations.auto-download=false"
    "-Dorg.gradle.java.installations.paths=${jdk21}"
    "-Dandroid.aapt2FromMavenOverride=${androidSdk}/share/android-sdk/build-tools/35.0.0/aapt2"
    "-Dorg.gradle.project.android.aapt2FromMavenOverride=${androidSdk}/share/android-sdk/build-tools/35.0.0/aapt2"
  ];

  installPhase = ''
    runHook preInstall
    apk_path="$(echo app/build/outputs/apk/release/*-release-unsigned.apk)"
    install -Dm644 "$apk_path" "$out/glimpse.apk"
    runHook postInstall
  '';

  meta = with lib; {
    description = "LineageOS Glimpse photo gallery app (unsigned APK)";
    homepage = "https://github.com/LineageOS/android_packages_apps_Glimpse";
    license = licenses.asl20;
    platforms = platforms.unix;
  };
})
