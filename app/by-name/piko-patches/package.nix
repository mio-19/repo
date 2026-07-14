{
  lib,
  stdenv,
  fetchFromGitHub,
  gradle_9_3_1,
  jdk21_headless,
  androidSdkBuilder,
  writableTmpDirAsHomeHook,
  morphe-patches-gradle-plugin_1_3_2,
  morphe-patches-library-m2_1_3_1,
  apktool-src,
  multidexlib2-src,
  morphe-patcher-src,
}:
let
  androidSdk = androidSdkBuilder (s: [
    s.cmdline-tools-latest
    s.platform-tools
    s.platforms-android-33
    s.platforms-android-34
    s.platforms-android-35
    s.platforms-android-36
    s.build-tools-34-0-0
    s.build-tools-35-0-0
    s.build-tools-36-0-0
  ]);

  gradle = gradle_9_3_1;

  morphe-cli-deps-filtered = lib.filterAttrs (
    name: _: !lib.any (pattern: !builtins.isNull (builtins.match pattern name)) [ "api.github" ]
  ) (lib.importJSON ../morphe-patches/morphe-patches_deps.json);

  hoodles-patches-deps = lib.importJSON ../hoodles-patches/morphe-patches_deps.json;
  brosssh-patches-deps = lib.importJSON ../brosssh-patches/morphe-patches_deps.json;
  piko-patches-deps = lib.importJSON ./piko-patches_deps.json;

in
stdenv.mkDerivation (finalAttrs: {
  pname = "piko-patches";
  version = "3.7.0";

  src = fetchFromGitHub {
    owner = "crimera";
    repo = "piko";
    rev = "v${finalAttrs.version}";
    hash = "sha256-qLgcZcMLlOFVo7gBnRbuAICSC12r00keRE/biMqPRm4=";
  };

  sourceRoot = "source";

  env = {
    JAVA_HOME = jdk21_headless.passthru.home;
    ANDROID_HOME = "${androidSdk}/share/android-sdk";
    ANDROID_SDK_ROOT = "${androidSdk}/share/android-sdk";
    ANDROID_AAPT2_FROM_MAVEN_OVERRIDE = "${androidSdk}/share/android-sdk/build-tools/36.0.0/aapt2";
    MORPHE_PLUGIN_M2 = "${morphe-patches-gradle-plugin_1_3_2}";
    MORPHE_LIBRARY_M2 = "${morphe-patches-library-m2_1_3_1}";
  };

  postUnpack = ''
    root="$PWD"
    cp -a ${morphe-patcher-src} "$root/morphe-patcher"
    chmod -R u+w "$root/morphe-patcher"
    cp -a ${apktool-src} "$root/Apktool"
    chmod -R u+w "$root/Apktool"

    cp -a ${multidexlib2-src} "$root/multidexlib2"
    chmod -R u+w "$root/multidexlib2"

    substituteInPlace "$sourceRoot/gradle/libs.versions.toml" \
      --replace-fail 'morphe-patches-library = "1.4.1"' 'morphe-patches-library = "1.3.1"'

    patch -d "$sourceRoot" -p0 < ${./settings.gradle.kts.patch}

    if [ -d "$sourceRoot/extensions/shared/library" ]; then
        mv "$sourceRoot/extensions/shared/library" "$sourceRoot/extensions/shared/piko-library"
    fi

    while IFS= read -r -d "" file; do
      if grep -Fq 'project(":extensions:shared:library")' "$file"; then
        substituteInPlace "$file" \
          --replace-fail 'project(":extensions:shared:library")' 'project(":extensions:shared:piko-library")'
      fi
    done < <(find "$sourceRoot" -name "build.gradle.kts" -print0)
  '';

  mitmCache = gradle.fetchDeps {
    pname = "piko-patches";
    pkg = finalAttrs.finalPackage;
    data = ./piko-patches_deps.json;
    silent = false;
    useBwrap = false;
  };

  passthru = {
    inherit (finalAttrs) mitmCache;
  };

  nativeBuildInputs = [
    gradle
    jdk21_headless
    writableTmpDirAsHomeHook
  ];

  preConfigure = ''
    export ANDROID_USER_HOME="$HOME/.android"
    mkdir -p "$ANDROID_USER_HOME"
    echo "sdk.dir=${androidSdk}/share/android-sdk" > local.properties
  '';

  gradleFlags = [
    "-Dorg.gradle.java.installations.auto-download=false"
    "-Dorg.gradle.java.installations.paths=${finalAttrs.env.JAVA_HOME}"
    "-Dmaven.repo.local=build/m2"
    "-Dandroid.aapt2FromMavenOverride=${androidSdk}/share/android-sdk/build-tools/36.0.0/aapt2"
    "-Dorg.gradle.project.android.aapt2FromMavenOverride=${androidSdk}/share/android-sdk/build-tools/36.0.0/aapt2"
  ];

  gradleBuildTask = "generatePatchesList";
  gradleUpdateTask = finalAttrs.gradleBuildTask;

  installPhase = ''
    runHook preInstall
    mkdir -p "$out"
    install -Dm644 "patches/build/libs/patches-${finalAttrs.version}.mpp" \
      "$out/patches-${finalAttrs.version}.mpp"
    runHook postInstall
  '';

  meta = with lib; {
    description = "Piko Morphe patches for Twitter/X";
    homepage = "https://github.com/crimera/piko";
    license = licenses.gpl3Only;
    platforms = platforms.unix;
  };
})
