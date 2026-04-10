{
  lib,
  stdenv,
  fetchFromGitHub,
  gradle_8_7,
  jdk17_headless,
  writableTmpDirAsHomeHook,
  git,
}:
let
  gradle = gradle_8_7;
in
stdenv.mkDerivation (finalAttrs: {
  pname = "nocubes_1_20_1";
  version = "master-38904f7";

  src = fetchFromGitHub {
    owner = "Cadiboo";
    repo = "NoCubes";
    rev = "38904f71b818a1f4770c5253b9a1dd522201babc";
    hash = "sha256-n+F4UAoVV65naLUHhJZtsKGqJqvAIw7wD4UUvvxQQEE=";
  };

  gradleBuildTask = ":fabric:remapJar";
  gradleUpdateTask = finalAttrs.gradleBuildTask;

  mitmCache = gradle.fetchDeps {
    pname = finalAttrs.pname;
    pkg = finalAttrs.finalPackage;
    data = ./nocubes_1_20_1_deps.json;
    silent = false;
    useBwrap = false;
  };

  nativeBuildInputs = [
    gradle
    jdk17_headless
    writableTmpDirAsHomeHook
    git
  ];

  env = {
    JAVA_HOME = if stdenv.isDarwin then "${jdk17_headless}" else "${jdk17_headless}/lib/openjdk";
  };

  gradleFlags = [
    "-Dorg.gradle.java.installations.auto-download=false"
    "-Dorg.gradle.java.installations.paths=${finalAttrs.env.JAVA_HOME}"
  ];

  # The upstream build derives the version from `git rev-parse` and fails in
  # source tarball builds (no .git directory). Allow fallback to "nogit".
  postPatch = ''
    substituteInPlace build.gradle \
      --replace-fail 'def result = exec {' $'def result = exec {\n\t\tignoreExitValue true'

    substituteInPlace settings.gradle \
      --replace-fail "id 'org.gradle.toolchains.foojay-resolver-convention' version '0.8.0'" ""

    # Avoid Sponge Vanilla project configuration requiring remote version manifest
    # in the lock-update/build environment.
    substituteInPlace common/build.gradle \
      --replace-fail "id 'org.spongepowered.gradle.vanilla'" ""
    substituteInPlace common/build.gradle \
      --replace-fail 'minecraft {' 'if (false) {'

    # Avoid building common as a separate Java project; Fabric compiles common
    # sources directly via source set wiring below.
    substituteInPlace fabric/build.gradle \
      --replace-fail "testImplementation(compileOnly(project(':common')))" ""
  '';

  installPhase = ''
    runHook preInstall

    mkdir -p "$out/share/minecraft-mods"

    jar_path="$(find fabric/build/libs -maxdepth 1 -type f -name '*.jar' \
      ! -name '*-sources*' ! -name '*-javadoc*' ! -name '*deobf*' | head -n 1)"

    if [[ -z "$jar_path" ]]; then
      jar_path="$(find fabric/build/libs -maxdepth 1 -type f -name '*.jar' | head -n 1)"
    fi

    test -n "$jar_path"
    install -Dm644 "$jar_path" "$out/share/minecraft-mods/nocubes-1.20.1-fabric.jar"

    runHook postInstall
  '';

  meta = with lib; {
    description = "NoCubes Fabric mod for Minecraft 1.20.1, built from source";
    homepage = "https://github.com/Cadiboo/NoCubes";
    license = licenses.lgpl3Only;
    platforms = platforms.unix;
  };
})
