{
  fetchFromGitHub,
  fetchurl,
  jdk21,
  lib,
  stdenv,
  javax_inject_1,
}:
stdenv.mkDerivation (finalAttrs: {
  pname = "dagger";
  version = "2.28.3";
  src = fetchFromGitHub {
    owner = "google";
    repo = "dagger";
    tag = "dagger-2.28.3";
    hash = "sha256-dKkP9MsdkbbAws8Xpv2BxssXuhF7mUnGwh0UEJ5Mtzo=";
  };
  pomFile = fetchurl {
    url = "https://repo.maven.apache.org/maven2/com/google/dagger/dagger/2.28.3/dagger-2.28.3.pom";
    hash = "sha256-JlupWajhPDoGEz8EtTkWnBAY2v/U0z9TxFOrTLOG9XA=";
  };
  nativeBuildInputs = [
    jdk21
    javax_inject_1
  ];
  dontConfigure = true;
  dontUnpack = true;
  installPhase = ''
    runHook preInstall; tmp="$(mktemp -d)"; trap 'rm -rf "''$tmp"' EXIT; cd "''$tmp"; mkdir -p classes; find  "${finalAttrs.src}/java/dagger" -name '*.java' | sort > sources.txt; ${jdk21}/bin/javac --release 8 -encoding UTF-8 -cp "${"cpArgs:1"}" -d classes @sources.txt; (cd classes; ${jdk21}/bin/jar cf "''$tmp/${finalAttrs.pname}-${finalAttrs.version}.jar" .); mkdir -p "''$out"; install -Dm644 "''$tmp/${finalAttrs.pname}-${finalAttrs.version}.jar" "''$out/${finalAttrs.pname}-${finalAttrs.version}.jar"; install -Dm644 "${finalAttrs.pomFile}" "''$out/${finalAttrs.pname}-${finalAttrs.version}.pom"; runHook postInstall
  '';
  meta = with lib; {
    description = "dagger";
    homepage = "https://github.com/google/dagger";
    license = licenses.asl20;
    platforms = platforms.unix;
  };
})
