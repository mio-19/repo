{
  fetchFromGitHub,
  fetchurl,
  jdk21,
  lib,
  stdenv,
}:
stdenv.mkDerivation (finalAttrs: {
  pname = "commons-compress";
  version = "1.21";
  src = fetchFromGitHub {
    owner = "apache";
    repo = "commons-compress";
    tag = "rel/1.21";
    hash = "sha256-sGHyM2dJ03knnU6DxH7P4QgJ57OAcTrlDWZGzBBG9QM=";
  };
  pomFile = fetchurl {
    url = "https://repo.maven.apache.org/maven2/org/apache/commons/commons-compress/1.21/commons-compress-1.21.pom";
    hash = "sha256-Z1uwI8m+7d4yMpSZebl0Kl/qlGKApVobRi1Mp4AQiM0=";
  };
  nativeBuildInputs = [ jdk21 ];
  dontConfigure = true;
  dontUnpack = true;
  installPhase = ''
    runHook preInstall; tmp="$(mktemp -d)"; trap 'rm -rf "''$tmp"' EXIT; cd "''$tmp"; mkdir -p classes; find  "${finalAttrs.src}/src/main/java" -name '*.java' | sort > sources.txt; ${jdk21}/bin/javac --release 8 -encoding UTF-8  -d classes @sources.txt; (cd classes; ${jdk21}/bin/jar cf "''$tmp/${finalAttrs.pname}-${finalAttrs.version}.jar" .); mkdir -p "''$out"; install -Dm644 "''$tmp/${finalAttrs.pname}-${finalAttrs.version}.jar" "''$out/${finalAttrs.pname}-${finalAttrs.version}.jar"; install -Dm644 "${finalAttrs.pomFile}" "''$out/${finalAttrs.pname}-${finalAttrs.version}.pom"; runHook postInstall
  '';
  meta = with lib; {
    description = "commons-compress";
    homepage = "https://github.com/apache/commons-compress";
    license = licenses.asl20;
    platforms = platforms.unix;
  };
})
