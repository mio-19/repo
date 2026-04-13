{
  fetchFromGitHub,
  jdk21_headless,
  lib,
  stdenv,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "javapoet";
  version = "1.10.0";

  src = fetchFromGitHub {
    owner = "square";
    repo = "javapoet";
    tag = "javapoet-${finalAttrs.version}";
    hash = "sha256-ctnKNEspjFCGMcJYu2TDQMR+h8aJU/f4SX5cEWE/tKc=";
  };

  nativeBuildInputs = [ jdk21_headless ];

  dontConfigure = true;
  dontUnpack = true;

  installPhase = ''
    runHook preInstall

    tmp="$(mktemp -d)"
    trap 'rm -rf "$tmp"' EXIT
    cd "$tmp"

    mkdir -p classes
    find "${finalAttrs.src}/src/main/java" -name '*.java' | sort > sources.txt
    javac --release 8 -encoding UTF-8 -d classes @sources.txt

    (
      cd classes
      jar cf "$tmp/javapoet-${finalAttrs.version}.jar" .
    )

    mkdir -p "$out"
    install -Dm644 "$tmp/javapoet-${finalAttrs.version}.jar" "$out/javapoet-${finalAttrs.version}.jar"
    install -Dm644 "${finalAttrs.src}/pom.xml" "$out/javapoet-${finalAttrs.version}.pom"

    runHook postInstall
  '';

  meta = with lib; {
    description = "Java API for generating .java source files";
    homepage = "https://github.com/square/javapoet";
    license = licenses.asl20;
    platforms = platforms.unix;
  };
})
