{
  lib,
  jdk21,
  gradle-packages,
  stdenv,
  fetchFromGitHub,
  writableTmpDirAsHomeHook,
  androidSdkBuilder,
}:
let
  androidSdk = androidSdkBuilder (s: [
    s.cmdline-tools-latest
    s.platform-tools
    s.platforms-android-34
    s.build-tools-34-0-0
    s.ndk-27-3-13750724
  ]);

  gradle =
    (gradle-packages.mkGradle {
      version = "8.13";
      hash = "sha256-IPGxF2I3JUpvwgTYQ0GW+hGkz7OHVnUZxhVW6HEK7Xg=";
      defaultJava = jdk21;
    }).wrapped;

  version = "v3_openjdk-258a8488";
in
stdenv.mkDerivation (finalAttrs: {
  pname = "amethyst";
  inherit version;

  src = fetchFromGitHub {
    owner = "AngelAuraMC";
    repo = "Amethyst-Android";
    rev = "258a8488b62a19313a8def8eaaaa6ade7d6982fc";
    hash = "sha256-hYuwzEjMg7K0QJsYDTeZ+MIAczENYZXmxyLg+2MS6pg=";
    fetchSubmodules = true;
  };

  gradleBuildTask = ":app_pojavlauncher:assembleRelease";
  gradleUpdateTask = finalAttrs.gradleBuildTask;

  mitmCache = gradle.fetchDeps {
    inherit (finalAttrs) pname;
    pkg = finalAttrs.finalPackage;
    data = ./amethyst_deps.json;
    silent = false;
    useBwrap = false;
  };

  nativeBuildInputs = [
    gradle
    jdk21
    writableTmpDirAsHomeHook
  ];

  env = {
    JAVA_HOME = jdk21;
    ANDROID_HOME = "${androidSdk}/share/android-sdk";
    ANDROID_SDK_ROOT = "${androidSdk}/share/android-sdk";
    ANDROID_NDK_HOME = "${androidSdk}/share/android-sdk/ndk/27.3.13750724";
    ANDROID_NDK_ROOT = "${androidSdk}/share/android-sdk/ndk/27.3.13750724";
    AMETHYST_VERSION_NAME = version;
    CURSEFORGE_API_KEY = "DUMMY";
  };

  preConfigure = ''
    export ANDROID_USER_HOME="$HOME/.android"
    mkdir -p "$ANDROID_USER_HOME"
    cat > local.properties <<EOF
    sdk.dir=${androidSdk}/share/android-sdk
    ndk.dir=${androidSdk}/share/android-sdk/ndk/27.3.13750724
    EOF
  '';

  postPatch = ''
    substituteInPlace app_pojavlauncher/build.gradle \
      --replace-fail '        abortOnError false' $'        abortOnError false\n        checkReleaseBuilds false' \
      --replace-fail '        versionName getVersionName()' '        versionName System.getenv("AMETHYST_VERSION_NAME") ?: getVersionName()' \
      --replace-fail '            signingConfig signingConfigs.customRelease' ""
  '';

  gradleFlags = [
    "-Dorg.gradle.java.installations.auto-download=false"
    "-Dorg.gradle.java.installations.paths=${jdk21}"
    "-Dandroid.aapt2FromMavenOverride=${androidSdk}/share/android-sdk/build-tools/34.0.0/aapt2"
    "-Dorg.gradle.project.android.aapt2FromMavenOverride=${androidSdk}/share/android-sdk/build-tools/34.0.0/aapt2"
  ];

  installPhase = ''
    runHook preInstall
    apk_path="$(echo app_pojavlauncher/build/outputs/apk/release/*.apk)"
    install -Dm644 "$apk_path" "$out/amethyst.apk"
    runHook postInstall
  '';

  meta = with lib; {
    description = "Amethyst Android Minecraft launcher";
    homepage = "https://github.com/AngelAuraMC/Amethyst-Android";
    license = licenses.gpl3Only;
    platforms = platforms.unix;
  };
})
