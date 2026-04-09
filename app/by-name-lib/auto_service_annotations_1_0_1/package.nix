{
  fetchFromGitHub,
  fetchurl,
  jdk21,
  lib,
  stdenv,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "auto-service-annotations";
  version = "1.0.1";

  src = fetchFromGitHub {
    owner = "google";
    repo = "auto";
    tag = "auto-service-${finalAttrs.version}";
    hash = "sha256-iPGeaAX6BFzXKBhmnhYYC++v1VhSaexET5IvhV4Dlqc=";
  };

  pomFile = fetchurl {
    url = "https://repo.maven.apache.org/maven2/com/google/auto/service/auto-service-annotations/1.0.1/auto-service-annotations-1.0.1.pom";
    hash = "sha256-6bvxs9ZsoYAEpqB6INv6EMos6DZzSPdB3i/o/vzmjMI=";
  };

  aggregatorPomFile = fetchurl {
    url = "https://repo.maven.apache.org/maven2/com/google/auto/service/auto-service-aggregator/1.0.1/auto-service-aggregator-1.0.1.pom";
    hash = "sha256-BIFGDbWZAzYrJvq9O9zV7CAHUPk5G7tlAv48fcLfPkw=";
  };

  nativeBuildInputs = [ jdk21 ];

  dontConfigure = true;
  dontUnpack = true;

  installPhase = ''
    runHook preInstall

    tmp="$(mktemp -d)"
    trap 'rm -rf "$tmp"' EXIT
    cd "$tmp"

    mkdir -p classes
    find "${finalAttrs.src}/service/annotations/src/main/java" -name '*.java' | sort > sources.txt
    ${jdk21}/bin/javac --release 8 -encoding UTF-8 -d classes @sources.txt

    (
      cd classes
      ${jdk21}/bin/jar cf "$tmp/auto-service-annotations-${finalAttrs.version}.jar" .
    )

    mkdir -p "$out"
    install -Dm644 "$tmp/auto-service-annotations-${finalAttrs.version}.jar" "$out/auto-service-annotations-${finalAttrs.version}.jar"
    install -Dm644 "${finalAttrs.pomFile}" "$out/auto-service-annotations-${finalAttrs.version}.pom"
    install -Dm644 "${finalAttrs.aggregatorPomFile}" "$out/auto-service-aggregator-${finalAttrs.version}.pom"

    runHook postInstall
  '';

  meta = with lib; {
    description = "Service provider annotation for Java ServiceLoader";
    homepage = "https://github.com/google/auto";
    license = licenses.asl20;
    platforms = platforms.unix;
  };
})
