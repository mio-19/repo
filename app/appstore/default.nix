{
  lib,
  jdk21,
  jdk17,
  gradle-packages,
  stdenv,
  fetchFromGitHub,
  apksigner,
  writableTmpDirAsHomeHook,
  androidSdkBuilder,
}:
let
  androidSdk = androidSdkBuilder (s: [
    s.cmdline-tools-latest
    s.platform-tools
    s.platforms-android-36
    s.build-tools-36-1-0
  ]);

  gradle =
    (gradle-packages.mkGradle {
      version = "9.4.0";
      hash = "sha256-YOpyM1bYEmPoAC/sD8+eKw7uDAhQx6PXqwpj8szGAfM=";
      defaultJava = jdk21;
    }).wrapped;
in
stdenv.mkDerivation (finalAttrs: {
  pname = "appstore";
  version = "0ccf3283bde9f53616e6e940d98aae5424c2ae5a";

  src = fetchFromGitHub {
    owner = "GrapheneOS";
    repo = "AppStore";
    rev = finalAttrs.version;
    hash = "sha256-gBTkQBik0ZgX71Qitv17lsICJm7unO/3Hk2FMkKHXsw=";
  };

  gradleBuildTask = ":app:assembleRelease";
  gradleUpdateTask = finalAttrs.gradleBuildTask;

  mitmCache = gradle.fetchDeps {
    inherit (finalAttrs) pname;
    pkg = finalAttrs.finalPackage;
    data = "appstore_deps.json";
    silent = false;
    useBwrap = false;
  };

  nativeBuildInputs = [
    gradle
    jdk21
    jdk17
    apksigner
    writableTmpDirAsHomeHook
  ];

  env = {
    JAVA_HOME = "${jdk21}/lib/openjdk";
    ANDROID_HOME = "${androidSdk}/share/android-sdk";
    ANDROID_SDK_ROOT = "${androidSdk}/share/android-sdk";
    ANDROID_AAPT2_FROM_MAVEN_OVERRIDE = "${androidSdk}/share/android-sdk/build-tools/36.1.0/aapt2";
  };

  preConfigure = ''
    export ANDROID_USER_HOME="$HOME/.android"
    mkdir -p "$ANDROID_USER_HOME"
    echo "sdk.dir=${androidSdk}/share/android-sdk" > local.properties
  '';

  gradleFlags = [
    "-Dorg.gradle.java.installations.auto-download=false"
    "-Dorg.gradle.java.installations.paths=${jdk17}/lib/openjdk,${jdk21}/lib/openjdk"
    "-Dandroid.aapt2FromMavenOverride=${androidSdk}/share/android-sdk/build-tools/36.1.0/aapt2"
    "-Dorg.gradle.project.android.aapt2FromMavenOverride=${androidSdk}/share/android-sdk/build-tools/36.1.0/aapt2"
  ];

  installPhase = ''
    runHook preInstall
    apk_path="$(echo app/build/outputs/apk/release/*-release-unsigned.apk)"
    install -Dm644 "$apk_path" "$out/appstore.apk"
    runHook postInstall
  '';

  meta = with lib; {
    description = "GrapheneOS App Store app (unsigned APK)";
    homepage = "https://github.com/GrapheneOS/AppStore";
    license = licenses.asl20;
    platforms = platforms.unix;
  };
})
