{
  fetchFromGitHub,
  lib,
  stdenv,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "commons-parent";
  version = "69";

  src = fetchFromGitHub {
    owner = "apache";
    repo = "commons-parent";
    tag = "rel/commons-parent-${finalAttrs.version}";
    hash = "sha256-mQBTLdBJBWpgw0SW7Z3VM8gWCc1Zjdw1oWiUg7g/DKs=";
  };

  dontConfigure = true;
  dontBuild = true;
  dontUnpack = true;

  installPhase = ''
    runHook preInstall

    mkdir -p "$out"
    install -Dm644 "${finalAttrs.src}/pom.xml" "$out/commons-parent-${finalAttrs.version}.pom"

    runHook postInstall
  '';

  meta = with lib; {
    description = "Apache Commons parent POM";
    homepage = "https://github.com/apache/commons-parent";
    license = licenses.asl20;
    platforms = platforms.unix;
  };
})
