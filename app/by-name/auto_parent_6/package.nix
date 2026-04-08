{
  fetchFromGitHub,
  lib,
  stdenv,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "auto-parent";
  version = "6";

  src = fetchFromGitHub {
    owner = "google";
    repo = "auto";
    tag = "auto-parent-${finalAttrs.version}";
    hash = "sha256-4vjmrvp9m5VeMa0IlK0tLNtd/Nfwx3csche7chhe59A=";
  };

  dontConfigure = true;
  dontBuild = true;
  dontUnpack = true;

  installPhase = ''
    runHook preInstall

    mkdir -p "$out"
    install -Dm644 "${finalAttrs.src}/pom.xml" "$out/auto-parent-${finalAttrs.version}.pom"

    runHook postInstall
  '';

  meta = with lib; {
    description = "Parent POM for Google Auto projects";
    homepage = "https://github.com/google/auto";
    license = licenses.asl20;
    platforms = platforms.unix;
  };
})
