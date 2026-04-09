{
  fetchFromGitHub,
  jdk21,
  lib,
  stdenv,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "slf4j";
  version = "1.5.3";

  src = fetchFromGitHub {
    owner = "qos-ch";
    repo = "slf4j";
    tag = "SLF4J_${finalAttrs.version}";
    hash = "sha256-dKGhXZMwuWbznalhWLtNk2aSmNhWimMbIYQikiA1Ji4=";
  };

  nativeBuildInputs = [ jdk21 ];

  dontConfigure = true;
  dontUnpack = true;

  installPhase = ''
    runHook preInstall

    tmp="$(mktemp -d)"
    trap 'rm -rf "$tmp"' EXIT
    cd "$tmp"

    mkdir -p api-classes jcl-classes
    find "${finalAttrs.src}/slf4j-api/src/main/java" -name '*.java' | sort > api-sources.txt
    ${jdk21}/bin/javac --release 8 -encoding ISO-8859-1 -d api-classes @api-sources.txt
    rm -rf api-classes/org/slf4j/impl

    find "${finalAttrs.src}/jcl-over-slf4j/src/main/java" -name '*.java' | sort > jcl-sources.txt
    ${jdk21}/bin/javac --release 8 -encoding ISO-8859-1 -cp api-classes -d jcl-classes @jcl-sources.txt

    (
      cd api-classes
      ${jdk21}/bin/jar cf "$tmp/slf4j-api-${finalAttrs.version}.jar" .
    )
    (
      cd jcl-classes
      ${jdk21}/bin/jar cf "$tmp/jcl-over-slf4j-${finalAttrs.version}.jar" .
    )

    mkdir -p "$out"
    install -Dm644 "$tmp/slf4j-api-${finalAttrs.version}.jar" "$out/slf4j-api-${finalAttrs.version}.jar"
    install -Dm644 "$tmp/jcl-over-slf4j-${finalAttrs.version}.jar" "$out/jcl-over-slf4j-${finalAttrs.version}.jar"
    install -Dm644 "${finalAttrs.src}/slf4j-api/pom.xml" "$out/slf4j-api-${finalAttrs.version}.pom"
    install -Dm644 "${finalAttrs.src}/jcl-over-slf4j/pom.xml" "$out/jcl-over-slf4j-${finalAttrs.version}.pom"

    runHook postInstall
  '';

  meta = with lib; {
    description = "Simple Logging Facade for Java plus JCL bridge";
    homepage = "https://www.slf4j.org/";
    license = licenses.mit;
    platforms = platforms.unix;
  };
})
