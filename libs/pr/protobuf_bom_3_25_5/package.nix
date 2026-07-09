{
  fetchFromGitHub,
  lib,
  stdenv,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "protobuf-bom";
  version = "3.25.5";

  src = fetchFromGitHub {
    owner = "protocolbuffers";
    repo = "protobuf";
    tag = "v${finalAttrs.version}";
    hash = "sha256-DFLlk4T8ODo3lmvrANlkIsrmDXZHmqMPTYxDWaz56qA=";
  };

  dontConfigure = true;
  dontBuild = true;
  dontUnpack = true;

  installPhase = ''
    runHook preInstall
    mkdir -p "$out"
    install -Dm644 "${finalAttrs.src}/java/bom/pom.xml" "$out/protobuf-bom-${finalAttrs.version}.pom"
    runHook postInstall
  '';

  meta = with lib; {
    description = "Protocol Buffers BOM POM";
    homepage = "https://github.com/protocolbuffers/protobuf";
    license = licenses.bsd3;
    platforms = platforms.unix;
  };
})
