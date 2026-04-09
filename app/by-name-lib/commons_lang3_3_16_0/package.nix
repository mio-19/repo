{
  fetchFromGitHub,
  jdk25,
  lib,
  stdenv,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "commons-lang3";
  version = "3.16.0";

  src = fetchFromGitHub {
    owner = "apache";
    repo = "commons-lang";
    tag = "rel/commons-lang-${finalAttrs.version}";
    hash = "sha256-yAoe4RTTATMzAPf7yPMOomdXvSfeG9VUPvVYpf22sHU=";
  };

  nativeBuildInputs = [ jdk25 ];

  dontConfigure = true;
  dontUnpack = true;

  installPhase = ''
    runHook preInstall

    tmp="$(mktemp -d)"
    trap 'rm -rf "$tmp"' EXIT
    cd "$tmp"

    mkdir -p classes
    find "${finalAttrs.src}/src/main/java" -name '*.java' | sort > sources.txt
    ${jdk25}/bin/javac --release 8 -encoding ISO-8859-1 -d classes @sources.txt

    (
      cd classes
      ${jdk25}/bin/jar cf "$tmp/commons-lang3-${finalAttrs.version}.jar" .
    )

    mkdir -p "$out"
    install -Dm644 "$tmp/commons-lang3-${finalAttrs.version}.jar" "$out/commons-lang3-${finalAttrs.version}.jar"
    install -Dm644 "${finalAttrs.src}/pom.xml" "$out/commons-lang3-${finalAttrs.version}.pom"

    runHook postInstall
  '';

  meta = with lib; {
    description = "Apache Commons Lang";
    homepage = "https://commons.apache.org/proper/commons-lang/";
    license = licenses.asl20;
    platforms = platforms.unix;
  };
})
