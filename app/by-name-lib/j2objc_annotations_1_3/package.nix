{
  fetchFromGitHub,
  fetchurl,
  jdk21,
  lib,
  stdenv,
}:
stdenv.mkDerivation (finalAttrs: {
  pname = "j2objc-annotations";
  version = "1.3";
  src = fetchFromGitHub {
    owner = "google";
    repo = "j2objc";
    tag = "1.3";
    hash = "sha256-G1kNLFRExJ2WQZ9GK/5PE9RRmZs4DH9CGDbN0YV7Iqw=";
  };
  pomFile = fetchurl {
    url = "https://repo.maven.apache.org/maven2/com/google/j2objc/j2objc-annotations/1.3/j2objc-annotations-1.3.pom";
    hash = "sha256-X6yoJLoRW+5FhzAzff2y/OpGui/XdNQwTtvzD6aj8FU=";
  };
  nativeBuildInputs = [ jdk21 ];
  dontConfigure = true;
  dontUnpack = true;
  installPhase = ''
    runHook preInstall; tmp="$(mktemp -d)"; trap 'rm -rf "''$tmp"' EXIT; cd "''$tmp"; mkdir -p classes; find  "${finalAttrs.src}/annotations/src/main/java" -name '*.java' | sort > sources.txt; ${jdk21}/bin/javac --release 8 -encoding UTF-8  -d classes @sources.txt; (cd classes; ${jdk21}/bin/jar cf "''$tmp/${finalAttrs.pname}-${finalAttrs.version}.jar" .); mkdir -p "''$out"; install -Dm644 "''$tmp/${finalAttrs.pname}-${finalAttrs.version}.jar" "''$out/${finalAttrs.pname}-${finalAttrs.version}.jar"; install -Dm644 "${finalAttrs.pomFile}" "''$out/${finalAttrs.pname}-${finalAttrs.version}.pom"; runHook postInstall
  '';
  meta = with lib; {
    description = "j2objc-annotations";
    homepage = "https://github.com/google/j2objc";
    license = licenses.asl20;
    platforms = platforms.unix;
  };
})
