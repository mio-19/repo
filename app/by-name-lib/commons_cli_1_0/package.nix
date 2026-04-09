{
  commons_lang_2_3,
  fetchFromGitHub,
  jdk25,
  lib,
  stdenv,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "commons-cli";
  version = "1.0";

  src = fetchFromGitHub {
    owner = "apache";
    repo = "commons-cli";
    tag = "CLI_1_0";
    hash = "sha256-HwS1RdyGNuPZJoKWQX9X9KwNs013M1T5NBLSn4N9fKo=";
  };

  nativeBuildInputs = [ jdk25 ];

  dontConfigure = true;
  dontUnpack = true;

  installPhase = ''
    runHook preInstall

    tmp="$(mktemp -d)"
    trap 'rm -rf "$tmp"' EXIT
    cd "$tmp"

    mkdir -p classes
    find "${finalAttrs.src}/src/java" -name '*.java' | sort > sources.txt
    ${jdk25}/bin/javac --release 8 -cp "${commons_lang_2_3}/commons-lang-${commons_lang_2_3.version}.jar" -d classes @sources.txt

    (
      cd classes
      ${jdk25}/bin/jar cf "$tmp/commons-cli-${finalAttrs.version}.jar" .
    )

    mkdir -p "$out"
    install -Dm644 "$tmp/commons-cli-${finalAttrs.version}.jar" "$out/commons-cli-${finalAttrs.version}.jar"
    cat > "$out/commons-cli-${finalAttrs.version}.pom" <<EOF
    <project>
      <modelVersion>4.0.0</modelVersion>
      <groupId>commons-cli</groupId>
      <artifactId>commons-cli</artifactId>
      <version>${finalAttrs.version}</version>
    </project>
    EOF

    runHook postInstall
  '';

  meta = with lib; {
    description = "Apache Commons CLI";
    homepage = "https://commons.apache.org/proper/commons-cli/";
    license = licenses.asl20;
    platforms = platforms.unix;
  };
})
