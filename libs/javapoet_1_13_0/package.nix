{
  fetchFromGitHub,
  jdk25_headless,
  lib,
  stdenv,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "javapoet";
  version = "1.13.0";

  src = fetchFromGitHub {
    owner = "square";
    repo = "javapoet";
    tag = "javapoet-${finalAttrs.version}";
    hash = "sha256-Pj28ZTJFi9WB5Qnl8XIrSkRkzdA4De0o4vL9Ww9XjuA=";
  };

  nativeBuildInputs = [ jdk25_headless ];

  dontConfigure = true;
  dontUnpack = true;

  installPhase = ''
    runHook preInstall

    tmp="$(mktemp -d)"
    
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
