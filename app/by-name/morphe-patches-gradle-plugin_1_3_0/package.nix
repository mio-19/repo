{
  lib,
  stdenv,
  fetchFromGitHub,
  gradle-packages,
  jdk21_headless,
  writableTmpDirAsHomeHook,
}:
let
  gradle =
    (gradle-packages.mkGradle {
      version = "8.14.4";
      hash = "sha256-8XcSmKcPbbWina9iN4xOGKF/wzybprFDYuDN9AYQOA0=";
      defaultJava = jdk21_headless;
    }).wrapped;
in
stdenv.mkDerivation (finalAttrs: {
  pname = "morphe-patches-gradle-plugin";
  version = "1.3.0";

  src = fetchFromGitHub {
    owner = "MorpheApp";
    repo = "morphe-patches-gradle-plugin";
    rev = "v${finalAttrs.version}";
    hash = "sha256-Xk8PonGrd4sHmzROxDmV6fM11dL6jbfNyP9W/056hP8=";
  };

  gradleBuildTask = "publish";
  gradleUpdateTask = finalAttrs.gradleBuildTask;

  mitmCache = gradle.fetchDeps {
    pname = "morphe-patches-gradle-plugin";
    pkg = finalAttrs.finalPackage;
    data = ./morphe-patches-gradle-plugin_deps.json;
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
    GITHUB_ACTOR = "nix-build";
    GITHUB_TOKEN = "ghp_dummy";
  };

  postUnpack = ''
    patch -d "$sourceRoot" -p0 < ${./morphe-patches-gradle-plugin.patch}
    patch -d "$sourceRoot/src/main/kotlin/app/morphe/patches/gradle" -p0 < ${./morphe-patches-gradle-plugin-settings.patch}
    patch -d "$sourceRoot/src/main/kotlin/app/morphe/patches/gradle" -p0 < ${./morphe-patches-gradle-plugin-extension.patch}
  '';

  gradleFlags = [
    "-Dorg.gradle.java.installations.auto-download=false"
    "-Dorg.gradle.java.installations.paths=${finalAttrs.env.JAVA_HOME}"
  ];

  installPhase = ''
    runHook preInstall
    mkdir -p "$out"
    echo "Current directory: $PWD"
    echo "Checking for build/m2..."
    ls -R build/m2 || echo "build/m2 not found"
    if [ -d "build/m2" ]; then
      cp -a build/m2/. "$out/"
    fi
    find "$out" -name "*.pom"
    runHook postInstall
  '';

  meta = with lib; {
    description = "Morphe Patches Gradle Plugin pre-built to local maven repo";
    homepage = "https://github.com/MorpheApp/morphe-patches-gradle-plugin";
    license = licenses.gpl3Only;
    platforms = platforms.unix;
  };
})
