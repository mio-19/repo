{
  lib,
  stdenv,
  fetchFromGitHub,
  gradle_8_14_4,
  jdk21_headless,
  writableTmpDirAsHomeHook,
}:
let
  gradle = gradle_8_14_4;
in
stdenv.mkDerivation (finalAttrs: {
  pname = "morphe-patches-gradle-plugin";
  version = "1.3.2-dev.2";

  src = fetchFromGitHub {
    owner = "MorpheApp";
    repo = "morphe-patches-gradle-plugin";
    rev = "v${finalAttrs.version}";
    hash = "sha256-22sKVENFRZu7TMJGp0LelaEuZ+rkkI/7vVhK7Nr5ce0=";
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
    mv build/m2 "$out"
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
