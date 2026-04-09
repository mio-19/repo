{
  fetchFromGitHub,
  fetchurl,
  jdk21,
  lib,
  stdenv,
}:
stdenv.mkDerivation (finalAttrs: {
  pname = "error_prone_annotations";
  version = "2.11.0";
  src = fetchFromGitHub {
    owner = "google";
    repo = "error-prone";
    tag = "v2.11.0";
    hash = "sha256-GGtQrxD0EGGvhg4Lsl4vjDQzetOvb6NHPER9YtEfs2Y=";
  };
  pomFile = fetchurl {
    url = "https://repo.maven.apache.org/maven2/com/google/errorprone/error_prone_annotations/2.11.0/error_prone_annotations-2.11.0.pom";
    hash = "sha256-AmHKAfLS6awq4uznXULFYyOzhfspS2vJQ/Yu9Okt3wg=";
  };
  nativeBuildInputs = [ jdk21 ];
  dontConfigure = true;
  dontUnpack = true;
  installPhase = ''
    runHook preInstall; tmp="$(mktemp -d)"; trap 'rm -rf "''$tmp"' EXIT; cd "''$tmp"; mkdir -p classes; find  "${finalAttrs.src}/annotations/src/main/java" -name '*.java' | sort > sources.txt; ${jdk21}/bin/javac --release 8 -encoding UTF-8  -d classes @sources.txt; (cd classes; ${jdk21}/bin/jar cf "''$tmp/${finalAttrs.pname}-${finalAttrs.version}.jar" .); mkdir -p "''$out"; install -Dm644 "''$tmp/${finalAttrs.pname}-${finalAttrs.version}.jar" "''$out/${finalAttrs.pname}-${finalAttrs.version}.jar"; install -Dm644 "${finalAttrs.pomFile}" "''$out/${finalAttrs.pname}-${finalAttrs.version}.pom"; runHook postInstall
  '';
  meta = with lib; {
    description = "error_prone_annotations";
    homepage = "https://github.com/google/error-prone";
    license = licenses.asl20;
    platforms = platforms.unix;
  };
})
