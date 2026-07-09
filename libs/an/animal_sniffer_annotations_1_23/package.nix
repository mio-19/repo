{
  fetchFromGitHub,
  jdk25_headless,
  lib,
  stdenv,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "animal-sniffer-annotations";
  version = "1.23";

  src = fetchFromGitHub {
    owner = "mojohaus";
    repo = "animal-sniffer";
    tag = finalAttrs.version;
    hash = "sha256-0th/VveF/WKHrngC/vMWGuPxrjLmV1TNS/KOxMXujm0=";
  };

  nativeBuildInputs = [ jdk25_headless ];

  dontConfigure = true;
  dontUnpack = true;

  installPhase = ''
    runHook preInstall

    tmp="$(mktemp -d)"

    cd "$tmp"

    mkdir -p classes
    find "${finalAttrs.src}/animal-sniffer-annotations/src/main/java" -name '*.java' ! -name 'module-info.java' | sort > sources.txt
    javac --release 8 -encoding UTF-8 -d classes @sources.txt

    (
      cd classes
      jar cf "$tmp/animal-sniffer-annotations-${finalAttrs.version}.jar" .
    )

    mkdir -p "$out"
    install -Dm644 "$tmp/animal-sniffer-annotations-${finalAttrs.version}.jar" "$out/animal-sniffer-annotations-${finalAttrs.version}.jar"
    install -Dm644 "${finalAttrs.src}/animal-sniffer-annotations/pom.xml" "$out/animal-sniffer-annotations-${finalAttrs.version}.pom"

    runHook postInstall
  '';

  meta = with lib; {
    description = "Animal Sniffer annotations";
    homepage = "https://www.mojohaus.org/animal-sniffer/";
    license = licenses.mit;
    platforms = platforms.unix;
  };
})
