{
  fetchFromGitHub,
  lib,
  stdenv,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "apache-parent";
  version = "33";

  src = fetchFromGitHub {
    owner = "apache";
    repo = "maven-apache-parent";
    tag = "apache-${finalAttrs.version}";
    hash = "sha256-nGtMq9bUzpNP27Fz3BCZaDd6moJtVRadSoUgh7PVFxs=";
  };

  dontConfigure = true;
  dontBuild = true;
  dontUnpack = true;

  installPhase = ''
    runHook preInstall
    mkdir -p "$out"
    install -Dm644 "${finalAttrs.src}/pom.xml" "$out/apache-${finalAttrs.version}.pom"
    runHook postInstall
  '';

  meta = with lib; {
    description = "Apache parent POM";
    homepage = "https://github.com/apache/maven-apache-parent";
    license = licenses.asl20;
    platforms = platforms.unix;
  };
})
