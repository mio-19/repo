# Minimal install wrapper for source-built Maven versions.
# The old vendored nixpkgs copy referenced missing build-maven*.nix files and
# hard-coded jdk_headless in makeWrapper instead of the per-version jdk attr.
{
  lib,
  fetchurl,
  jdk_headless,
  makeWrapper,
  stdenvNoCC,
}:
stdenvNoCC.mkDerivation (finalAttrs: {
  pname = "maven";
  version = "3.9.12";

  src = fetchurl {
    url = "mirror://apache/maven/maven-3/${finalAttrs.version}/binaries/apache-maven-${finalAttrs.version}-bin.tar.gz";
    hash = "sha256-+iyZSHKSlsI6/Rj9AakPYs3aCaRhkbVKi8N2TC7ugS4=";
  };

  sourceRoot = ".";

  jdk = jdk_headless;

  nativeBuildInputs = [ makeWrapper ];

  installPhase = ''
    runHook preInstall

    mkdir -p $out/maven $out/bin
    mv apache-maven-${finalAttrs.version}/* $out/maven/

    makeWrapper $out/maven/bin/mvn $out/bin/mvn \
      --set-default JAVA_HOME "${finalAttrs.jdk.passthru.home}"
    makeWrapper $out/maven/bin/mvnDebug $out/bin/mvnDebug \
      --set-default JAVA_HOME "${finalAttrs.jdk.passthru.home}"

    runHook postInstall
  '';

  meta = {
    homepage = "https://maven.apache.org/";
    description = "Build automation tool (used primarily for Java projects)";
    license = lib.licenses.asl20;
    mainProgram = "mvn";
    inherit (finalAttrs.jdk.meta) platforms;
  };
})
