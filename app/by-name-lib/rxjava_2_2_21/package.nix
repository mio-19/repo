{
  fetchFromGitHub,
  fetchurl,
  jdk21,
  lib,
  stdenv,
  reactive_streams_1_0_3,
}:
stdenv.mkDerivation (finalAttrs: {
  pname = "rxjava";
  version = "2.2.21";
  src = fetchFromGitHub {
    owner = "ReactiveX";
    repo = "RxJava";
    tag = "v2.2.21";
    hash = "sha256-oWLOIRxUmTTKRHG4qke4Q1Tkp/tlsIMyXQK0/9i05tw=";
  };
  pomFile = fetchurl {
    url = "https://repo.maven.apache.org/maven2/io/reactivex/rxjava2/rxjava/2.2.21/rxjava-2.2.21.pom";
    hash = "sha256-slvs5QSD3po+Hf0lARwthTMCFu+Kgbhvar69vfmw8Sc=";
  };
  nativeBuildInputs = [
    jdk21
    reactive_streams_1_0_3
  ];
  dontConfigure = true;
  dontUnpack = true;
  installPhase = ''
    runHook preInstall; tmp="$(mktemp -d)"; trap 'rm -rf "''$tmp"' EXIT; cd "''$tmp"; mkdir -p classes; find  "${finalAttrs.src}/src/main/java" -name '*.java' | sort > sources.txt; ${jdk21}/bin/javac --release 8 -encoding UTF-8 -cp "${"cpArgs:1"}" -d classes @sources.txt; (cd classes; ${jdk21}/bin/jar cf "''$tmp/${finalAttrs.pname}-${finalAttrs.version}.jar" .); mkdir -p "''$out"; install -Dm644 "''$tmp/${finalAttrs.pname}-${finalAttrs.version}.jar" "''$out/${finalAttrs.pname}-${finalAttrs.version}.jar"; install -Dm644 "${finalAttrs.pomFile}" "''$out/${finalAttrs.pname}-${finalAttrs.version}.pom"; runHook postInstall
  '';
  meta = with lib; {
    description = "rxjava";
    homepage = "https://github.com/ReactiveX/RxJava";
    license = licenses.asl20;
    platforms = platforms.unix;
  };
})
