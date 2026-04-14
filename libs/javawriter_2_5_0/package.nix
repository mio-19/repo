{
  fetchFromGitHub,
  jdk25_headless,
  lib,
  stdenv,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "javawriter";
  version = "2.5.0";

  src = fetchFromGitHub {
    owner = "square";
    repo = "javawriter";
    tag = "javawriter-${finalAttrs.version}";
    hash = "sha256-k6anKX03CK+H6mL6wDxTNXU4DapoPyfe8jaKHbGlP0c=";
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
    javac --release 8 -d classes @sources.txt

    (
      cd classes
      jar cf "$tmp/javawriter-${finalAttrs.version}.jar" .
    )

    mkdir -p "$out"
    install -Dm644 "$tmp/javawriter-${finalAttrs.version}.jar" "$out/javawriter-${finalAttrs.version}.jar"
    install -Dm644 "${finalAttrs.src}/pom.xml" "$out/javawriter-${finalAttrs.version}.pom"

    runHook postInstall
  '';

  meta = with lib; {
    description = "Utility for generating Java source files";
    homepage = "https://github.com/square/javawriter";
    license = licenses.asl20;
    platforms = platforms.unix;
  };
})
