{
  fetchFromGitHub,
  lib,
  stdenv,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "oss-parent";
  version = "7";

  src = fetchFromGitHub {
    owner = "sonatype";
    repo = "oss-parents";
    tag = "oss-parent-${finalAttrs.version}";
    hash = "sha256-R6Rz8MoS7gjOZN0bYFdOR4xktogD65nOzTnvUGqde1I=";
  };

  dontConfigure = true;
  dontBuild = true;
  dontUnpack = true;

  installPhase = ''
    runHook preInstall

    mkdir -p "$out"
    install -Dm644 "${finalAttrs.src}/pom.xml" "$out/oss-parent-${finalAttrs.version}.pom"

    runHook postInstall
  '';

  meta = with lib; {
    description = "Sonatype OSS parent POM";
    homepage = "https://github.com/sonatype/oss-parents";
    license = licenses.asl20;
    platforms = platforms.unix;
  };
})
