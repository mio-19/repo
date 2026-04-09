{
  fetchFromGitHub,
  lib,
  stdenv,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "httpcomponents-core";
  version = "4.4.16";

  src = fetchFromGitHub {
    owner = "apache";
    repo = "httpcomponents-core";
    tag = "rel/v${finalAttrs.version}";
    hash = "sha256-2Fk8UnvEJDI95AV/92N3Jzg6MMHZdyRHQXsbpRq+Td4=";
  };

  dontConfigure = true;
  dontBuild = true;
  dontUnpack = true;

  installPhase = ''
    runHook preInstall
    mkdir -p "$out"
    install -Dm644 "${finalAttrs.src}/pom.xml" "$out/httpcomponents-core-${finalAttrs.version}.pom"
    runHook postInstall
  '';

  meta = with lib; {
    description = "Apache HttpComponents Core parent POM";
    homepage = "https://github.com/apache/httpcomponents-core";
    license = licenses.asl20;
    platforms = platforms.unix;
  };
})
