{
  lib,
  jdk21,
  gradle-packages,
  stdenv,
  fetchgit,
  apksigner,
  writableTmpDirAsHomeHook,
  androidSdkBuilder,
  git,
  gcc,
  cmake,
  gnumake,
  python3,
  python3Packages,
}:
let
  androidSdk = androidSdkBuilder (s: [
    s.cmdline-tools-latest
    s.platform-tools
    s.platforms-android-36
    s.build-tools-36-0-0
  ]);

  gradle =
    (gradle-packages.mkGradle {
      version = "9.4.0";
      hash = "sha256-YOpyM1bYEmPoAC/sD8+eKw7uDAhQx6PXqwpj8szGAfM=";
      defaultJava = jdk21;
    }).wrapped;

  pythonWithCrc32c = python3.withPackages (ps: [ ps.crc32c ]);
in
stdenv.mkDerivation (finalAttrs: {
  pname = "gadgetbridge";
  version = "0.90.0";

  src = fetchgit {
    url = "https://codeberg.org/Freeyourgadget/Gadgetbridge.git";
    rev = finalAttrs.version;
    fetchSubmodules = true;
    hash = "sha256-GqmfZPz0+Ed2D0Y/aYC0Mib1fYhsVRknc6HGKMu011o=";
  };

  patches = [
    ./deterministic-release-build.patch
    ./fix-fossil-hr-build.patch
  ];

  gradleBuildTask = ":app:assembleMainlineRelease";
  gradleUpdateTask = finalAttrs.gradleBuildTask;

  mitmCache = gradle.fetchDeps {
    inherit (finalAttrs) pname;
    pkg = finalAttrs.finalPackage;
    data = ./gadgetbridge_deps.json;
    silent = false;
    useBwrap = false;
  };

  nativeBuildInputs = [
    gradle
    jdk21
    apksigner
    writableTmpDirAsHomeHook
    git
    gcc
    gnumake
    pythonWithCrc32c
  ];

  env = {
    JAVA_HOME = jdk21;
    ANDROID_HOME = "${androidSdk}/share/android-sdk";
    ANDROID_SDK_ROOT = "${androidSdk}/share/android-sdk";
    ANDROID_AAPT2_FROM_MAVEN_OVERRIDE = "${androidSdk}/share/android-sdk/build-tools/36.0.0/aapt2";
    GADGETBRIDGE_VERSION_CODE = "246";
    GADGETBRIDGE_GIT_HASH_SHORT = "release";
  };

  postPatch = ''
    rm -f external/jerryscript/tools/babel/package.json
  '';

  preConfigure = ''
    export ANDROID_USER_HOME="$HOME/.android"
    mkdir -p "$ANDROID_USER_HOME"
    echo "sdk.dir=${androidSdk}/share/android-sdk" > local.properties
    export PATH=${cmake}/bin:$PATH

    pushd external
    ${stdenv.shell} ./build_fossil_hr_gbapps.sh
    popd
  '';

  gradleFlags = [
    "-Dorg.gradle.java.installations.auto-download=false"
    "-Dorg.gradle.java.installations.paths=${jdk21}"
    "-Dandroid.aapt2FromMavenOverride=${androidSdk}/share/android-sdk/build-tools/36.0.0/aapt2"
    "-Dorg.gradle.project.android.aapt2FromMavenOverride=${androidSdk}/share/android-sdk/build-tools/36.0.0/aapt2"
  ];

  installPhase = ''
    runHook preInstall
    apk_path="$(echo app/build/outputs/apk/mainline/release/*.apk | awk '{print $1}')"
    install -Dm644 "$apk_path" "$out/gadgetbridge.apk"
    runHook postInstall
  '';

  meta = with lib; {
    description = "Gadgetbridge wearable companion for Android";
    homepage = "https://codeberg.org/Freeyourgadget/Gadgetbridge";
    license = licenses.asl20;
    platforms = platforms.unix;
  };
})
