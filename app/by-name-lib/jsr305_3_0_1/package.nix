{
  fetchFromGitHub,
  fetchurl,
  jdk21,
  lib,
  stdenv,
}:
stdenv.mkDerivation (finalAttrs: {
  pname = "jsr305";
  version = "3.0.1";
  src = fetchFromGitHub {
    owner = "findbugsproject";
    repo = "findbugs";
    tag = "3.0.1";
    hash = "sha256-nuA1C0igBHQIzag7SKxupqM0n3mET6Ri3zE8ITEsrn0=";
  };
  pomFile = fetchurl {
    url = "https://repo.maven.apache.org/maven2/com/google/code/findbugs/jsr305/3.0.1/jsr305-3.0.1.pom";
    hash = "sha256-QXCnYdxb/TmBqOb3qrnirNzoLTT9Wqm7EePAkNJTFM4=";
  };
  nativeBuildInputs = [ jdk21 ];
  dontConfigure = true;
  dontUnpack = true;
  installPhase = ''
    runHook preInstall; tmp="$(mktemp -d)"; trap 'rm -rf "''$tmp"' EXIT; cd "''$tmp"; mkdir -p classes; find  "${finalAttrs.src}/jsr305/src/main/java" -name '*.java' | sort > sources.txt; ${jdk21}/bin/javac --release 8 -encoding UTF-8  -d classes @sources.txt; (cd classes; ${jdk21}/bin/jar cf "''$tmp/${finalAttrs.pname}-${finalAttrs.version}.jar" .); mkdir -p "''$out"; install -Dm644 "''$tmp/${finalAttrs.pname}-${finalAttrs.version}.jar" "''$out/${finalAttrs.pname}-${finalAttrs.version}.jar"; install -Dm644 "${finalAttrs.pomFile}" "''$out/${finalAttrs.pname}-${finalAttrs.version}.pom"; runHook postInstall
  '';
  meta = with lib; {
    description = "jsr305";
    homepage = "https://github.com/findbugsproject/findbugs";
    license = licenses.asl20;
    platforms = platforms.unix;
  };
})
