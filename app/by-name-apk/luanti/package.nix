{
  stdenv,
  lib,
  fetchFromGitHub,
  androidenv,
  jdk17,
  gradle_8,
  git,
  makeWrapper,
  writeShellScript,
  gradle,
  cacert,
}:
let
  version = "unstable-2026-04-01";

  src = fetchFromGitHub {
    owner = "luanti-org";
    repo = "luanti";
    rev = "f5d92d8ea5f4497b2142a7b04860f96cf5916c35";
    hash = "sha256-EYImy7Dz8DjoQv8ec/mV9WjAgl6y8sQn1e12vbzRsxo=";
    fetchSubmodules = true;
  };

  androidComposition = androidenv.composeAndroidPackages {
    toolsVersion = "26.1.1";
    platformVersions = [ "35" ];
    abiVersions = [ "arm64-v8a" ];
    includeNDK = true;
    ndkVersions = [ "29.0.14206865" ];
    cmakeVersions = [ "3.31.7" ];
    includeEmulator = false;
    includeSystemImages = false;
    useGoogleAPIs = false;
    useGoogleTVAddOns = false;
  };

  androidSdk = androidComposition.androidsdk;
in
stdenv.mkDerivation (finalAttrs: {
  pname = "luanti";
  inherit version src;

  nativeBuildInputs = [
    jdk17
    androidSdk
    gradle_8
    makeWrapper
    git
    gradle
    cacert
  ];

  dontUseCmakeConfigure = true;

  sourceRoot = "source/android";

  postPatch = ''
    cat > gradle.properties <<EOF
    android.builder.sdkDownload=false
    org.gradle.java.home=${jdk17}
    android.aapt2FromMavenOverride=${androidSdk}/libexec/android-sdk/build-tools/35.0.0/aapt2
    org.gradle.project.android.aapt2FromMavenOverride=${androidSdk}/libexec/android-sdk/build-tools/35.0.0/aapt2
    EOF

    cat > local.properties <<EOF
    sdk.dir=${androidSdk}/libexec/android-sdk
    ndk.dir=${androidSdk}/libexec/android-sdk/ndk-bundle
    cmake.dir=${androidSdk}/libexec/android-sdk/cmake/3.31.7
    EOF

    substituteInPlace gradlew --replace-fail '/usr/bin/env sh' '${stdenv.shell}'
  '';

  configurePhase = ''
    runHook preConfigure
    export JAVA_HOME=${jdk17}
    export ANDROID_HOME=${androidSdk}/libexec/android-sdk
    export ANDROID_SDK_ROOT=$ANDROID_HOME
    export ANDROID_NDK_HOME=$ANDROID_HOME/ndk-bundle
    export ANDROID_NDK_ROOT=$ANDROID_HOME/ndk-bundle
    export PATH=${lib.makeBinPath [ jdk17 gradle_8 ]}:$PATH
    runHook postConfigure
  '';

  buildPhase = ''
    runHook preBuild
    chmod +x ./gradlew
    ./gradlew --no-daemon --offline --stacktrace --info \
      -Dorg.gradle.java.home=${jdk17} \
      -Dorg.gradle.jvmargs="-Xmx4g -XX:MaxMetaspaceSize=1g" \
      :app:assembleDebug
    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall
    apk_path="app/build/intermediates/apk/debug/app-arm64-v8a-debug.apk"
    test -f "$apk_path"
    install -Dm644 "$apk_path" "$out/luanti.apk"
    runHook postInstall
  '';

  meta = {
    description = "Luanti (formerly Minetest) Android APK";
    homepage = "https://www.luanti.org/";
    license = lib.licenses.lgpl21Plus;
    platforms = [ "aarch64-linux" "x86_64-linux" ];
  };
})
