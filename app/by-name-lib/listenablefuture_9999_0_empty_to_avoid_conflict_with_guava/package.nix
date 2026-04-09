{
  fetchurl,
  jdk21_headless,
  lib,
  stdenv,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "listenablefuture";
  version = "9999.0-empty-to-avoid-conflict-with-guava";

  pomFile = fetchurl {
    url = "https://repo.maven.apache.org/maven2/com/google/guava/listenablefuture/9999.0-empty-to-avoid-conflict-with-guava/listenablefuture-9999.0-empty-to-avoid-conflict-with-guava.pom";
    hash = "sha256-GNSx2yYVPU5VB5zh92ux/gXNuGLvmVSojLzE/zi4Z5s=";
  };

  nativeBuildInputs = [ jdk21_headless ];

  dontConfigure = true;
  dontUnpack = true;

  installPhase = ''
    runHook preInstall

    tmp="$(mktemp -d)"
    trap 'rm -rf "$tmp"' EXIT
    cd "$tmp"

    mkdir empty
    (
      cd empty
      jar cf "$tmp/listenablefuture-${finalAttrs.version}.jar" .
    )

    mkdir -p "$out"
    install -Dm644 "$tmp/listenablefuture-${finalAttrs.version}.jar" "$out/listenablefuture-${finalAttrs.version}.jar"
    install -Dm644 "${finalAttrs.pomFile}" "$out/listenablefuture-${finalAttrs.version}.pom"

    runHook postInstall
  '';

  meta = with lib; {
    description = "Empty compatibility artifact for Guava's listenablefuture";
    homepage = "https://github.com/google/guava";
    license = licenses.asl20;
    platforms = platforms.unix;
  };
})
