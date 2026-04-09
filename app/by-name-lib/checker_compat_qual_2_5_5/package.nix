{
  fetchFromGitHub,
  fetchurl,
  jdk21,
  lib,
  stdenv,
}:
stdenv.mkDerivation (finalAttrs: {
  pname = "checker-compat-qual";
  version = "2.5.5";
  src = fetchFromGitHub {
    owner = "typetools";
    repo = "checker-framework";
    tag = "checker-framework-2.5.5";
    hash = "sha256-4tOgeTKK3Ghb1xCK9qrD8T9/LhdOrO90vFEYAXZ+1jQ=";
  };
  pomFile = fetchurl {
    url = "https://repo.maven.apache.org/maven2/org/checkerframework/checker-compat-qual/2.5.5/checker-compat-qual-2.5.5.pom";
    hash = "sha256-QvIevZGDvgSe5a/IIrNFQDpdp2QDeHVzSgObDW4DU74=";
  };
  nativeBuildInputs = [ jdk21 ];
  dontConfigure = true;
  dontUnpack = true;
  installPhase = ''
    runHook preInstall; tmp="$(mktemp -d)"; trap 'rm -rf "''$tmp"' EXIT; cd "''$tmp"; mkdir -p classes; find  "${finalAttrs.src}/checker-compat-qual/src/main/java" -name '*.java' | sort > sources.txt; ${jdk21}/bin/javac --release 8 -encoding UTF-8  -d classes @sources.txt; (cd classes; ${jdk21}/bin/jar cf "''$tmp/${finalAttrs.pname}-${finalAttrs.version}.jar" .); mkdir -p "''$out"; install -Dm644 "''$tmp/${finalAttrs.pname}-${finalAttrs.version}.jar" "''$out/${finalAttrs.pname}-${finalAttrs.version}.jar"; install -Dm644 "${finalAttrs.pomFile}" "''$out/${finalAttrs.pname}-${finalAttrs.version}.pom"; runHook postInstall
  '';
  meta = with lib; {
    description = "checker-compat-qual";
    homepage = "https://github.com/typetools/checker-framework";
    license = licenses.asl20;
    platforms = platforms.unix;
  };
})
