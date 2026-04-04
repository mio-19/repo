{
  lib,
  stdenv,
  fetchFromGitHub,
  gradle-packages,
  jdk17,
  writableTmpDirAsHomeHook,
  git,
}:
let
  gradle =
    (gradle-packages.mkGradle {
      version = "8.7";
      hash = "sha256-VEw11r2Emuil7QvOo5umd9xA9J330YNVYVgtogCblh0=";
      defaultJava = jdk17;
    }).wrapped;
in
stdenv.mkDerivation (finalAttrs: {
  pname = "nocubes_1_20_4";
  version = "1.20.4-fed43e9";

  src = fetchFromGitHub {
    owner = "Cadiboo";
    repo = "NoCubes";
    rev = "fed43e9c8a4687d80c2d57f8e7e8ceab6ff914f1";
    hash = "sha256-MVE/wbqupoXKvXg8eV+08oFtVwrxcZ+CBCDZwNdaKq0=";
  };

  gradleBuildTask = ":fabric:remapJar";
  gradleUpdateTask = finalAttrs.gradleBuildTask;

  mitmCache = gradle.fetchDeps {
    pname = finalAttrs.pname;
    pkg = finalAttrs.finalPackage;
    data = ./nocubes_1_20_4_deps.json;
    silent = false;
    useBwrap = false;
  };

  nativeBuildInputs = [
    gradle
    jdk17
    writableTmpDirAsHomeHook
    git
  ];

  env = {
    JAVA_HOME = if stdenv.isDarwin then "${jdk17}" else "${jdk17}/lib/openjdk";
  };

  gradleFlags = [
    "-Dorg.gradle.java.installations.auto-download=false"
    "-Dorg.gradle.java.installations.paths=${finalAttrs.env.JAVA_HOME}"
  ];

  postPatch = ''
    substituteInPlace build.gradle \
      --replace-fail 'def result = exec {' $'def result = exec {\n\t\tignoreExitValue true'

    substituteInPlace settings.gradle \
      --replace-fail "id 'org.gradle.toolchains.foojay-resolver-convention' version '0.8.0'" ""

    substituteInPlace common/build.gradle \
      --replace-fail "id 'org.spongepowered.gradle.vanilla'" ""
    substituteInPlace common/build.gradle \
      --replace-fail 'minecraft {' 'if (false) {'

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
    install -Dm644 "$jar_path" "$out/share/minecraft-mods/nocubes-1.20.4-fabric.jar"

    runHook postInstall
  '';

  meta = with lib; {
    description = "NoCubes Fabric mod for Minecraft 1.20.4, built from source";
    homepage = "https://github.com/Cadiboo/NoCubes";
    license = licenses.lgpl3Only;
    platforms = platforms.unix;
  };
})
