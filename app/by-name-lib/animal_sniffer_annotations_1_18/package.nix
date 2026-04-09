{
  fetchFromGitHub,
  fetchurl,
  jdk21,
  lib,
  stdenv,
}:
stdenv.mkDerivation (finalAttrs: {
  pname = "animal-sniffer-annotations";
  version = "1.18";
  src = fetchFromGitHub {
    owner = "mojohaus";
    repo = "animal-sniffer";
    tag = "animal-sniffer-parent-1.18";
    hash = "sha256-EsXyPXCk+3tizAyF1r31rQ+HL+BlTN1hXCaPCH1ROmQ=";
  };
  pomFile = fetchurl {
    url = "https://repo.maven.apache.org/maven2/org/codehaus/mojo/animal-sniffer-annotations/1.18/animal-sniffer-annotations-1.18.pom";
    hash = "sha256-rfUi9IOcNfUynql8QHrr6/qIB7ZEhS3E1c18l7em0uA=";
  };
  nativeBuildInputs = [ jdk21 ];
  dontConfigure = true;
  dontUnpack = true;
  installPhase = ''
    runHook preInstall; tmp="$(mktemp -d)"; trap 'rm -rf "''$tmp"' EXIT; cd "''$tmp"; mkdir -p classes; find  "${finalAttrs.src}/animal-sniffer-annotations/src/main/java" -name '*.java' | sort > sources.txt; ${jdk21}/bin/javac --release 8 -encoding UTF-8  -d classes @sources.txt; (cd classes; ${jdk21}/bin/jar cf "''$tmp/${finalAttrs.pname}-${finalAttrs.version}.jar" .); mkdir -p "''$out"; install -Dm644 "''$tmp/${finalAttrs.pname}-${finalAttrs.version}.jar" "''$out/${finalAttrs.pname}-${finalAttrs.version}.jar"; install -Dm644 "${finalAttrs.pomFile}" "''$out/${finalAttrs.pname}-${finalAttrs.version}.pom"; runHook postInstall
  '';
  meta = with lib; {
    description = "animal-sniffer-annotations";
    homepage = "https://github.com/mojohaus/animal-sniffer";
    license = licenses.asl20;
    platforms = platforms.unix;
  };
})
