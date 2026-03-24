{
  lib,
  jdk21,
  gradle-packages,
  stdenv,
  fetchFromGitHub,
  apksigner,
  writableTmpDirAsHomeHook,
  androidSdkBuilder,
  fetchpatch,
}:
let
  rev = "79338cb19f4b86cae4d2e81e6de60ba7f613bb9b";

  androidSdk = androidSdkBuilder (s: [
    s.cmdline-tools-latest
    s.platform-tools
    s.platforms-android-34
    s.build-tools-34-0-0
  ]);

  gradle =
    (gradle-packages.mkGradle {
      version = "8.5";
      hash = "sha256-nZJnhwZqCBc56CAIWDOLSmnoN8OoIaM6yp2wndSkECY=";
      defaultJava = jdk21;
    }).wrapped;
in
stdenv.mkDerivation (finalAttrs: {
  pname = "termux-styling";
  version = "unstable-2025-06-25";

  src = fetchFromGitHub {
    owner = "termux";
    repo = "termux-styling";
    rev = rev;
    hash = "sha256-sVKJFVloCruZUz9JhEdomizUM+S2vavk2c0C27lR8E4=";
  };

  patches = [
    (fetchpatch {
      name = "Fix Android 12 + 15";
      url = "https://github.com/termux/termux-styling/pull/263.patch";
      hash = "sha256-S40xTaUrnE7jAo+PNveVMp0S9NOvHbAi5ubVv0yxvmU=";
    })
  ];

  gradleBuildTask = ":app:assembleRelease";
  gradleUpdateTask = finalAttrs.gradleBuildTask;

  # Lock refresh steps:
  # 1. Build the updater:
  #    nix build --impure .#termux-styling.mitmCache.updateScript
  # 2. Copy the resulting fetch-deps.sh, replace its outPath= with
  #    /home/dev/Documents/repo/app/termux-styling/termux-styling_deps.json,
  #    and run it from the repo root.
  mitmCache = gradle.fetchDeps {
    inherit (finalAttrs) pname;
    pkg = finalAttrs.finalPackage;
    data = "termux-styling_deps.json";
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
    ANDROID_AAPT2_FROM_MAVEN_OVERRIDE = "${androidSdk}/share/android-sdk/build-tools/34.0.0/aapt2";
  };

  postPatch = ''
    substituteInPlace app/build.gradle \
      --replace-fail '        versionCode 1000' '        versionCode 1001' \
      --replace-fail '        versionName "0.32.1"' '        versionName "0.32.1+git.20250625"'

    mv app/src/main/assets/colors/rosé-pine.properties app/src/main/assets/colors/rose-pine.properties
    mv app/src/main/assets/colors/rosé-pine-dawn.properties app/src/main/assets/colors/rose-pine-dawn.properties
    mv app/src/main/assets/colors/rosé-pine-moon.properties app/src/main/assets/colors/rose-pine-moon.properties
  '';

  preConfigure = ''
    export ANDROID_USER_HOME="$HOME/.android"
    mkdir -p "$ANDROID_USER_HOME"
    echo "sdk.dir=${androidSdk}/share/android-sdk" > local.properties
  '';

  gradleFlags = [
    "-Dorg.gradle.java.installations.auto-download=false"
    "-Dorg.gradle.java.installations.paths=${jdk21}"
    "-Dandroid.aapt2FromMavenOverride=${androidSdk}/share/android-sdk/build-tools/34.0.0/aapt2"
    "-Dorg.gradle.project.android.aapt2FromMavenOverride=${androidSdk}/share/android-sdk/build-tools/34.0.0/aapt2"
  ];

  installPhase = ''
    runHook preInstall
    apk_path="$(find app/build/outputs/apk/release -type f -name '*.apk' | head -n 1)"
    test -n "$apk_path" && test -f "$apk_path"
    install -Dm644 "$apk_path" "$out/termux-styling.apk"
    runHook postInstall
  '';

  meta = with lib; {
    description = "Termux plugin providing terminal color schemes and fonts";
    homepage = "https://github.com/termux/termux-styling";
    license = licenses.gpl3Only;
    platforms = platforms.unix;
  };
})
