{
  fetchFromGitHub,
  lib,
  stdenv,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "httpcomponents-client";
  version = "4.5.14";

  src = fetchFromGitHub {
    owner = "apache";
    repo = "httpcomponents-client";
    tag = "rel/v${finalAttrs.version}";
    hash = "sha256-WrOA/EQ+Y3HWkYXQgiEdTcfYyZ+16aIJ0HCwiYISxEY=";
  };

  dontConfigure = true;
  dontBuild = true;
  dontUnpack = true;

  installPhase = ''
    runHook preInstall
    mkdir -p "$out"
    install -Dm644 "${finalAttrs.src}/pom.xml" "$out/httpcomponents-client-${finalAttrs.version}.pom"
    runHook postInstall
  '';

  meta = with lib; {
    description = "Apache HttpComponents Client parent POM";
    homepage = "https://github.com/apache/httpcomponents-client";
    license = licenses.asl20;
    platforms = platforms.unix;
  };
})
