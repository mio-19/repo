{
  fetchFromGitHub,
  jdk21,
  lib,
  stdenv,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "commons-io";
  version = "1.3.1";

  src = fetchFromGitHub {
    owner = "apache";
    repo = "commons-io";
    tag = "IO_1_3_1";
    hash = "sha256-B71LBor7ML8dw585AHbhszrfLsNocTDskOTidV3vY0o=";
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
    find "${finalAttrs.src}/src/java" -name '*.java' | sort > sources.txt
    ${jdk21}/bin/javac --release 8 -d classes @sources.txt

    (
      cd classes
      ${jdk21}/bin/jar cf "$tmp/commons-io-${finalAttrs.version}.jar" .
    )

    mkdir -p "$out"
    install -Dm644 "$tmp/commons-io-${finalAttrs.version}.jar" "$out/commons-io-${finalAttrs.version}.jar"
    cat > "$out/commons-io-${finalAttrs.version}.pom" <<EOF
    <project>
      <modelVersion>4.0.0</modelVersion>
      <groupId>commons-io</groupId>
      <artifactId>commons-io</artifactId>
      <version>${finalAttrs.version}</version>
    </project>
    EOF

    runHook postInstall
  '';

  meta = with lib; {
    description = "Apache Commons IO library";
    homepage = "https://commons.apache.org/proper/commons-io/";
    license = licenses.asl20;
    platforms = platforms.unix;
  };
})
