{
  fetchFromGitHub,
  fetchurl,
  jdk21,
  lib,
  stdenv,
}:
stdenv.mkDerivation (finalAttrs: {
  pname = "checker-qual";
  version = "2.5.8";
  src = fetchFromGitHub {
    owner = "typetools";
    repo = "checker-framework";
    tag = "checker-framework-2.5.8";
    hash = "sha256-OgXR8AQRdt240hYMPUsR/W7Tz4fV72MKmYivoFM1rjk=";
  };
  pomFile = fetchurl {
    url = "https://repo.maven.apache.org/maven2/org/checkerframework/checker-qual/2.5.8/checker-qual-2.5.8.pom";
    hash = "sha256-M6xqDxNBrpZkfH1EZfSqPST+l9Jpe87izq5vyLXvLDw=";
  };
  nativeBuildInputs = [ jdk21 ];
  dontConfigure = true;
  dontUnpack = true;
  installPhase = ''
    runHook preInstall; tmp="$(mktemp -d)"; trap 'rm -rf "''$tmp"' EXIT; cd "''$tmp"; mkdir -p classes; find  "${finalAttrs.src}/checker-qual/src/main/java" -name '*.java' | sort > sources.txt; ${jdk21}/bin/javac --release 8 -encoding UTF-8  -d classes @sources.txt; (cd classes; ${jdk21}/bin/jar cf "''$tmp/${finalAttrs.pname}-${finalAttrs.version}.jar" .); mkdir -p "''$out"; install -Dm644 "''$tmp/${finalAttrs.pname}-${finalAttrs.version}.jar" "''$out/${finalAttrs.pname}-${finalAttrs.version}.jar"; install -Dm644 "${finalAttrs.pomFile}" "''$out/${finalAttrs.pname}-${finalAttrs.version}.pom"; runHook postInstall
  '';
  meta = with lib; {
    description = "checker-qual";
    homepage = "https://github.com/typetools/checker-framework";
    license = licenses.asl20;
    platforms = platforms.unix;
  };
})
