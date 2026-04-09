{
  fetchFromGitHub,
  fetchurl,
  jdk21,
  lib,
  stdenv,
}:
stdenv.mkDerivation (finalAttrs: {
  pname = "reactive-streams";
  version = "1.0.3";
  src = fetchFromGitHub {
    owner = "reactive-streams";
    repo = "reactive-streams-jvm";
    tag = "v1.0.3";
    hash = "sha256-wE7SvTmSqVST4p6GPhLXbXnMiu4YBKPShPY/Tl69XgI=";
  };
  pomFile = fetchurl {
    url = "https://repo.maven.apache.org/maven2/org/reactivestreams/reactive-streams/1.0.3/reactive-streams-1.0.3.pom";
    hash = "sha256-zO1GcXX0JXgz9ssHUQ/5ezx1oG4aWNiCo515hT1RxgI=";
  };
  nativeBuildInputs = [ jdk21 ];
  dontConfigure = true;
  dontUnpack = true;
  installPhase = ''
    runHook preInstall; tmp="$(mktemp -d)"; trap 'rm -rf "''$tmp"' EXIT; cd "''$tmp"; mkdir -p classes; find  "${finalAttrs.src}/api/src/main/java" -name '*.java' | sort > sources.txt; ${jdk21}/bin/javac --release 8 -encoding UTF-8  -d classes @sources.txt; (cd classes; ${jdk21}/bin/jar cf "''$tmp/${finalAttrs.pname}-${finalAttrs.version}.jar" .); mkdir -p "''$out"; install -Dm644 "''$tmp/${finalAttrs.pname}-${finalAttrs.version}.jar" "''$out/${finalAttrs.pname}-${finalAttrs.version}.jar"; install -Dm644 "${finalAttrs.pomFile}" "''$out/${finalAttrs.pname}-${finalAttrs.version}.pom"; runHook postInstall
  '';
  meta = with lib; {
    description = "reactive-streams";
    homepage = "https://github.com/reactive-streams/reactive-streams-jvm";
    license = licenses.asl20;
    platforms = platforms.unix;
  };
})
