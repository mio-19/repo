{
  fetchFromGitHub,
  jdk25_headless,
  lib,
  stdenv,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "xz-java";
  version = "1.9";

  src = fetchFromGitHub {
    owner = "tukaani-project";
    repo = "xz-java";
    tag = "v${finalAttrs.version}";
    hash = "sha256-W3CtViPiyMbDIAPlu5zbUdvhMkZLVxZzB9niT49jNbE=";
  };

  nativeBuildInputs = [ jdk25_headless ];

  dontConfigure = true;
  dontUnpack = true;

  installPhase = ''
    runHook preInstall

    tmp="$(mktemp -d)"
    
    cd "$tmp"

    mkdir -p classes
    find "${finalAttrs.src}/src/org/tukaani/xz" -name '*.java' > sources.txt
    javac --release 8 -d classes @sources.txt

    (
      cd classes
      jar cf "$tmp/xz-${finalAttrs.version}.jar" .
    )

    mkdir -p "$out"
    install -Dm644 "$tmp/xz-${finalAttrs.version}.jar" "$out/xz-${finalAttrs.version}.jar"
    cat > "$out/xz-${finalAttrs.version}.pom" <<EOF
    <project>
      <modelVersion>4.0.0</modelVersion>
      <groupId>org.tukaani</groupId>
      <artifactId>xz</artifactId>
      <version>${finalAttrs.version}</version>
    </project>
    EOF

    runHook postInstall
  '';

  meta = with lib; {
    description = "XZ data compression Java library";
    homepage = "https://tukaani.org/xz/java.html";
    license = licenses.publicDomain;
    platforms = platforms.unix;
  };
})
