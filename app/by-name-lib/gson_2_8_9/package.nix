{
  fetchFromGitHub,
  fetchurl,
  jdk21,
  lib,
  stdenv,
}:
stdenv.mkDerivation (finalAttrs: {
  pname = "gson";
  version = "2.8.9";
  src = fetchFromGitHub {
    owner = "google";
    repo = "gson";
    tag = "gson-parent-2.8.9";
    hash = "sha256-jKVpO5NHGitR+MACqg20ul3Kx5eVn0iiopGJYL/dIdo=";
  };
  pomFile = fetchurl {
    url = "https://repo.maven.apache.org/maven2/com/google/code/gson/gson/2.8.9/gson-2.8.9.pom";
    hash = "sha256-r97W5qaQ+/OtSuZa2jl/CpCl9jCzA9G3QbnJeSb91N4=";
  };
  nativeBuildInputs = [ jdk21 ];
  dontConfigure = true;
  dontUnpack = true;
  installPhase = ''
    runHook preInstall; tmp="$(mktemp -d)"; trap 'rm -rf "''$tmp"' EXIT; cd "''$tmp"; mkdir -p classes; find  "${finalAttrs.src}/gson/src/main/java" -name '*.java' | sort > sources.txt; ${jdk21}/bin/javac --release 8 -encoding UTF-8  -d classes @sources.txt; (cd classes; ${jdk21}/bin/jar cf "''$tmp/${finalAttrs.pname}-${finalAttrs.version}.jar" .); mkdir -p "''$out"; install -Dm644 "''$tmp/${finalAttrs.pname}-${finalAttrs.version}.jar" "''$out/${finalAttrs.pname}-${finalAttrs.version}.jar"; install -Dm644 "${finalAttrs.pomFile}" "''$out/${finalAttrs.pname}-${finalAttrs.version}.pom"; runHook postInstall
  '';
  meta = with lib; {
    description = "gson";
    homepage = "https://github.com/google/gson";
    license = licenses.asl20;
    platforms = platforms.unix;
  };
})
