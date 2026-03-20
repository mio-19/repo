{
  lib,
  jdk17,
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
    s.platforms-android-30
    s.build-tools-30-0-2
    s.ndk-21-4-7075529
  ]);

  gradle =
    (gradle-packages.mkGradle {
      version = "7.2";
      hash = "sha256-9YFwmpw16cuS4W9YXSxLyZsrGl+F0rrb09xr/1nh5t0=";
      defaultJava = jdk17;
    }).wrapped;
in
stdenv.mkDerivation (finalAttrs: {
  pname = "termux-app";
  version = "0.118.3";

  src = fetchFromGitHub {
    owner = "termux";
    repo = "termux-app";
    tag = "v${finalAttrs.version}";
    hash = "sha256-MEGHS23nrZwl+FQrQm3oIEzWio+qEJdhsP1jvZp4hTk=";
  };

  bootstrapAarch64 = fetchurl {
    url = "https://github.com/termux/termux-packages/releases/download/bootstrap-2025.03.28-r1+apt-android-7/bootstrap-aarch64.zip";
    hash = "sha256-yNcCtvdCk1ABw3zagbisaVBKldXPKPKJlTLdjNSwV+s=";
  };

  bootstrapArm = fetchurl {
    url = "https://github.com/termux/termux-packages/releases/download/bootstrap-2025.03.28-r1+apt-android-7/bootstrap-arm.zip";
    hash = "sha256-87udGzJVKzT/9Bhh2/GT7FuihI1n13msHHJW2mZA+F0=";
  };

  bootstrapI686 = fetchurl {
    url = "https://github.com/termux/termux-packages/releases/download/bootstrap-2025.03.28-r1+apt-android-7/bootstrap-i686.zip";
    hash = "sha256-Nts+GsNUf5oXT9djvZpIT6GjRJzdgeHPJAj/BFT4OcY=";
  };

  bootstrapX86_64 = fetchurl {
    url = "https://github.com/termux/termux-packages/releases/download/bootstrap-2025.03.28-r1+apt-android-7/bootstrap-x86_64.zip";
    hash = "sha256-HBJOwjlu5wpRsLCldPKapllSaqK59Vj5k7L7BdHlGFU=";
  };

  gradleBuildTask = ":app:assembleRelease";
  gradleUpdateTask = finalAttrs.gradleBuildTask;

  mitmCache = gradle.fetchDeps {
    inherit (finalAttrs) pname;
    pkg = finalAttrs.finalPackage;
    data = "termux_deps.json";
    silent = false;
    useBwrap = false;
  };

  nativeBuildInputs = [
    gradle
    jdk17
    apksigner
    writableTmpDirAsHomeHook
  ];

  env = {
    JAVA_HOME = jdk17;
    JITPACK_NDK_VERSION = "21.4.7075529";
    TERMUX_SPLIT_APKS_FOR_RELEASE_BUILDS = "0";
    ANDROID_AAPT2_FROM_MAVEN_OVERRIDE = "${androidSdk}/share/android-sdk/build-tools/30.0.2/aapt2";
  };

  preConfigure = ''
    export ANDROID_USER_HOME="$HOME/.android"
    mkdir -p "$ANDROID_USER_HOME"

    sdkRoot="$PWD/android-sdk"
    mkdir -p "$sdkRoot/build-tools" "$sdkRoot/platforms" "$sdkRoot/ndk"
    cp -a "${androidSdk}/share/android-sdk/build-tools/30.0.2" "$sdkRoot/build-tools/"
    ln -s "${androidSdk}/share/android-sdk/platforms/android-30" "$sdkRoot/platforms/android-30"
    ln -s "${androidSdk}/share/android-sdk/platform-tools" "$sdkRoot/platform-tools"
    ln -s "${androidSdk}/share/android-sdk/ndk/21.4.7075529" "$sdkRoot/ndk/21.4.7075529"
    cp -a "${androidSdk}/share/android-sdk/licenses" "$sdkRoot/"

    export ANDROID_HOME="$sdkRoot"
    export ANDROID_SDK_ROOT="$sdkRoot"
    export ANDROID_NDK_ROOT="$sdkRoot/ndk/21.4.7075529"
    echo "sdk.dir=$sdkRoot" > local.properties

    cp "${finalAttrs.bootstrapAarch64}" app/src/main/cpp/bootstrap-aarch64.zip
    cp "${finalAttrs.bootstrapArm}" app/src/main/cpp/bootstrap-arm.zip
    cp "${finalAttrs.bootstrapI686}" app/src/main/cpp/bootstrap-i686.zip
    cp "${finalAttrs.bootstrapX86_64}" app/src/main/cpp/bootstrap-x86_64.zip
  '';

  gradleFlags = [
    "-Dorg.gradle.java.installations.auto-download=false"
    "-Dorg.gradle.java.installations.paths=${jdk17}"
    "-Dandroid.aapt2FromMavenOverride=${androidSdk}/share/android-sdk/build-tools/30.0.2/aapt2"
    "-Dorg.gradle.project.android.aapt2FromMavenOverride=${androidSdk}/share/android-sdk/build-tools/30.0.2/aapt2"
  ];

  installPhase = ''
    runHook preInstall

    apk_path="$(echo app/build/outputs/apk/release/*universal*.apk | awk '{print $1}')"
    if [[ ! -f "$apk_path" ]]; then
      apk_path="$(echo app/build/outputs/apk/release/*.apk | awk '{print $1}')"
    fi

    install -Dm644 "$apk_path" "$out/termux.apk"
    runHook postInstall
  '';

  meta = with lib; {
    description = "Termux terminal emulator for Android built from source";
    homepage = "https://github.com/termux/termux-app";
    license = licenses.gpl3Only;
    platforms = platforms.unix;
  };
})
