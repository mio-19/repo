{
  lib,
  stdenv,
  fetchFromGitHub,
  gradle_9_4_1,
  jdk21_headless,
  androidSdkBuilder,
  writableTmpDirAsHomeHook,
  morphe-patcher-src,
  morphe-library-m2,
  apktool-src,
  multidexlib2-src,
}:
let
  androidSdk = androidSdkBuilder (s: [
    s.cmdline-tools-latest
    s.platform-tools
    s.platforms-android-33
    s.platforms-android-36
    s.build-tools-36-0-0
  ]);

  gradle = gradle_9_4_1;

  arsclib-src = fetchFromGitHub {
    owner = "MorpheApp";
    repo = "ARSCLib";
    rev = "d003b5ff1ca91fb8c5105619cf1108b450387061";
    hash = "sha256-2UO6zDAFeURrt9U9f7gNDA8J5X3o8Ct96/rItUq644g=";
  };
in
stdenv.mkDerivation (finalAttrs: {
  pname = "morphe-patches-library-m2";
  version = "1.0.2-dev.4";

  src = fetchFromGitHub {
    owner = "MorpheApp";
    repo = "morphe-patches-library";
    rev = "v${finalAttrs.version}";
    hash = "sha256-kbQx1xwy5eBrJiIYT8eEIWdU9/ukH4+58Aa4NpN9E3g=";
  };

  gradleBuildTask = "publish";
  gradleUpdateTask = finalAttrs.gradleBuildTask;

  mitmCache = gradle.fetchDeps {
    pname = "morphe-patches-library";
    pkg = finalAttrs.finalPackage;
    data = ./morphe-patches-library_deps.json;
    silent = false;
    useBwrap = false;
  };

  nativeBuildInputs = [
    gradle
    jdk21_headless
    writableTmpDirAsHomeHook
  ];

  env = {
    JAVA_HOME = if stdenv.isDarwin then "${jdk21_headless}" else "${jdk21_headless}/lib/openjdk";
    ANDROID_HOME = "${androidSdk}/share/android-sdk";
    ANDROID_SDK_ROOT = "${androidSdk}/share/android-sdk";
    ANDROID_AAPT2_FROM_MAVEN_OVERRIDE = "${androidSdk}/share/android-sdk/build-tools/36.0.0/aapt2";
    MORPHE_LIBRARY_M2 = "${morphe-library-m2}";
    GITHUB_ACTOR = "nix-build";
    GITHUB_TOKEN = "ghp_dummy";
  };

  postUnpack = ''
    root="$PWD"
    cp -a ${morphe-patcher-src} "$root/morphe-patcher"
    chmod -R u+w "$root/morphe-patcher"
    cp -a ${arsclib-src} "$root/ARSCLib"
    chmod -R u+w "$root/ARSCLib"
    cp -a ${apktool-src} "$root/Apktool"
    chmod -R u+w "$root/Apktool"
    patch -d "$root/Apktool" -p3 < ${../brosssh-patches/apktool-gradle-9.patch}
    cp -a ${multidexlib2-src} "$root/multidexlib2"
    chmod -R u+w "$root/multidexlib2"
    patch -d "$root/multidexlib2" -p3 < ${../brosssh-patches/multidexlib2-gradle-9.patch}

    substituteInPlace "$sourceRoot/settings.gradle.kts" \
      --replace-fail \
      'gradlePluginPortal()' \
      'gradlePluginPortal()
        mavenCentral()'

    substituteInPlace "$sourceRoot/patch-library/build.gradle.kts" \
      --replace-fail \
      'url = uri("https://maven.pkg.github.com/MorpheApp/morphe-patches-library")' \
      'url = uri("file://" + rootProject.projectDir.resolve("build/m2").absolutePath)'
    substituteInPlace "$sourceRoot/extension-library/build.gradle.kts" \
      --replace-fail \
      'url = uri("https://maven.pkg.github.com/MorpheApp/morphe-patches-library")' \
      'url = uri("file://" + rootProject.projectDir.resolve("build/m2").absolutePath)'
    substituteInPlace "$sourceRoot/patch-library/build.gradle.kts" \
      --replace-fail \
      $'                credentials {\n                    username = providers.gradleProperty("gpr.user").getOrElse(System.getenv("GITHUB_ACTOR"))\n                    password = providers.gradleProperty("gpr.key").getOrElse(System.getenv("GITHUB_TOKEN"))\n                }' \
      ""
    substituteInPlace "$sourceRoot/extension-library/build.gradle.kts" \
      --replace-fail \
      $'                credentials {\n                    username = providers.gradleProperty("gpr.user").getOrElse(System.getenv("GITHUB_ACTOR"))\n                    password = providers.gradleProperty("gpr.key").getOrElse(System.getenv("GITHUB_TOKEN"))\n                }' \
      ""
  '';

  preConfigure = ''
    export ANDROID_USER_HOME="$HOME/.android"
    mkdir -p "$ANDROID_USER_HOME"
    echo "sdk.dir=${androidSdk}/share/android-sdk" > local.properties
  '';

  gradleFlags = [
    "--refresh-dependencies"
    "-Dorg.gradle.java.installations.auto-download=false"
    "-Dorg.gradle.java.installations.paths=${finalAttrs.env.JAVA_HOME}"
    "-Dandroid.aapt2FromMavenOverride=${androidSdk}/share/android-sdk/build-tools/36.0.0/aapt2"
    "-Dorg.gradle.project.android.aapt2FromMavenOverride=${androidSdk}/share/android-sdk/build-tools/36.0.0/aapt2"
  ];

  installPhase = ''
    runHook preInstall
    mv build/m2 "$out"
    runHook postInstall
  '';

  meta = with lib; {
    description = "Morphe patches library pre-built to local maven repo";
    homepage = "https://github.com/MorpheApp/morphe-patches-library";
    license = licenses.gpl3Only;
    platforms = platforms.unix;
  };
})
