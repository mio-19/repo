{
  fetchFromGitHub,
  jdk25_headless,
  lib,
  stdenv,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "commons-codec";
  version = "1.2";

  src = fetchFromGitHub {
    owner = "apache";
    repo = "commons-codec";
    tag = "CODEC_1_2";
    hash = "sha256-1H5RsT56N8fn1EVTxkYzi2XjPHSs4R+gi2rJ4DluQcE=";
  };

  nativeBuildInputs = [ jdk25_headless ];

  dontConfigure = true;
  dontUnpack = true;

  installPhase = ''
    runHook preInstall

    tmp="$(mktemp -d)"
    trap 'rm -rf "$tmp"' EXIT
    cd "$tmp"

    mkdir -p classes
    find "${finalAttrs.src}/src/java" -name '*.java' | sort > sources.txt
    javac --release 8 -d classes @sources.txt

    (
      cd classes
      jar cf "$tmp/commons-codec-${finalAttrs.version}.jar" .
    )

    mkdir -p "$out"
    install -Dm644 "$tmp/commons-codec-${finalAttrs.version}.jar" "$out/commons-codec-${finalAttrs.version}.jar"
    cat > "$out/commons-codec-${finalAttrs.version}.pom" <<EOF
    <project>
      <modelVersion>4.0.0</modelVersion>
      <groupId>commons-codec</groupId>
      <artifactId>commons-codec</artifactId>
      <version>${finalAttrs.version}</version>
    </project>
    EOF

    runHook postInstall
  '';

  meta = with lib; {
    description = "Apache Commons Codec";
    homepage = "https://commons.apache.org/proper/commons-codec/";
    license = licenses.asl20;
    platforms = platforms.unix;
  };
})
