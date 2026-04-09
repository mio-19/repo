{
  fetchFromGitHub,
  jdk21,
  lib,
  stdenv,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "zxing-core";
  version = "3.5.4";

  src = fetchFromGitHub {
    owner = "zxing";
    repo = "zxing";
    tag = "zxing-${finalAttrs.version}";
    hash = "sha256-D+ZKfDa406RIaTRhH9yXxgP8EpGe0iQU9CqkOMC4UdE=";
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
    find "${finalAttrs.src}/core/src/main/java" -name '*.java' | sort > sources.txt
    ${jdk21}/bin/javac --release 8 -d classes @sources.txt

    (
      cd classes
      ${jdk21}/bin/jar cf "$tmp/core-${finalAttrs.version}.jar" .
    )

    mkdir -p "$out"
    install -Dm644 "$tmp/core-${finalAttrs.version}.jar" "$out/core-${finalAttrs.version}.jar"
    install -Dm644 "${finalAttrs.src}/core/pom.xml" "$out/core-${finalAttrs.version}.pom"
    install -Dm644 "${finalAttrs.src}/pom.xml" "$out/zxing-parent-${finalAttrs.version}.pom"

    runHook postInstall
  '';

  meta = with lib; {
    description = "ZXing core barcode encoding and decoding library";
    homepage = "https://github.com/zxing/zxing";
    license = licenses.asl20;
    platforms = platforms.unix;
  };
})
