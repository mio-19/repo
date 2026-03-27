{
  lib,
  jdk21,
  jdk17,
  gradle-packages,
  stdenv,
  src,
  version,
  fetchpatch,
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
  inherit version src;

  patches = [
    #./0001-always-show-vanadium.patch # TODO: not actually work
    (fetchpatch {
      name = "Fix details screen shared axis transition grouping";
      url = "https://github.com/GrapheneOS/AppStore/pull/469.patch";
      hash = "sha256-/V0ZvhOLtceDjUG2JIsPWg4KgGQRzSdQe2kQ+pF7QXE=";
    })
    (fetchpatch {
      name = "Do not reserve space for an icon in settings list";
      url = "https://github.com/GrapheneOS/AppStore/pull/395.patch";
      hash = "sha256-s9tNIzOb10ENMe7urrbQcE2o/q/fGmBAzgdxkEZQjd0=";
    })
  ];

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
    JAVA_HOME = if stdenv.isDarwin then "${jdk21}" else "${jdk21}/lib/openjdk";
    ANDROID_HOME = "${androidSdk}/share/android-sdk";
    ANDROID_SDK_ROOT = "${androidSdk}/share/android-sdk";
    ANDROID_AAPT2_FROM_MAVEN_OVERRIDE = "${androidSdk}/share/android-sdk/build-tools/36.1.0/aapt2";
  };

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
      "-xlintVitalRelease"
      "-Dorg.gradle.java.installations.auto-download=false"
      "-Dorg.gradle.java.installations.paths=${jdk17}${postfix},${jdk21}${postfix}"
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
