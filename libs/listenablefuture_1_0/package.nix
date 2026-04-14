{
  fetchFromGitHub,
  fetchurl,
  jdk25_headless,
  lib,
  stdenv,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "listenablefuture";
  version = "1.0";

  src = fetchFromGitHub {
    owner = "google";
    repo = "guava";
    tag = "v${finalAttrs.version}";
    hash = "sha256-HLYZC5HSuwuZwI0PYYY7FGjc1DzHigwsCoc9tOZzJYg=";
  };

  pomFile = fetchurl {
    url = "https://repo.maven.apache.org/maven2/com/google/guava/listenablefuture/1.0/listenablefuture-1.0.pom";
    hash = "sha256-U4c8rya8HtilZ+psk5qyqqP0el4y1creld31CA0jI4o=";
  };

  nativeBuildInputs = [ jdk25_headless ];

  dontConfigure = true;
  dontUnpack = true;

  installPhase = ''
    runHook preInstall

    tmp="$(mktemp -d)"

    cd "$tmp"

    mkdir -p classes
    javac --release 8 -encoding UTF-8 -d classes \
      "${finalAttrs.src}/src/com/google/common/util/concurrent/ListenableFuture.java"

    (
      cd classes
      jar cf "$tmp/listenablefuture-${finalAttrs.version}.jar" .
    )

    mkdir -p "$out"
    install -Dm644 "$tmp/listenablefuture-${finalAttrs.version}.jar" "$out/listenablefuture-${finalAttrs.version}.jar"
    install -Dm644 "${finalAttrs.pomFile}" "$out/listenablefuture-${finalAttrs.version}.pom"

    runHook postInstall
  '';

  meta = with lib; {
    description = "ListenableFuture interface extracted from Guava";
    homepage = "https://github.com/google/guava";
    license = licenses.asl20;
    platforms = platforms.unix;
  };
})
