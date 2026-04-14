{
  fetchFromGitHub,
  jdk8_headless,
  lib,
  stdenv,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "commons-lang";
  version = "2.3";

  src = fetchFromGitHub {
    owner = "apache";
    repo = "commons-lang";
    tag = "LANG_2_3";
    hash = "sha256-6wun5Ilc77K4aqiVfhDK6AB12gATojdxpJojRYc/qkA=";
  };

  nativeBuildInputs = [ jdk8_headless ];

  dontConfigure = true;
  dontUnpack = true;

  installPhase = ''
    runHook preInstall

    tmp="$(mktemp -d)"

    cd "$tmp"

    mkdir -p classes
    find "${finalAttrs.src}/src/java" -name '*.java' > sources.txt
    ${jdk8_headless}/bin/javac -source 1.4 -target 1.4 -encoding ISO-8859-1 -d classes @sources.txt

    (
      cd classes
      ${jdk8_headless}/bin/jar cf "$tmp/commons-lang-${finalAttrs.version}.jar" .
    )

    mkdir -p "$out"
    install -Dm644 "$tmp/commons-lang-${finalAttrs.version}.jar" "$out/commons-lang-${finalAttrs.version}.jar"
    cat > "$out/commons-lang-${finalAttrs.version}.pom" <<EOF
    <project>
      <modelVersion>4.0.0</modelVersion>
      <groupId>commons-lang</groupId>
      <artifactId>commons-lang</artifactId>
      <version>${finalAttrs.version}</version>
    </project>
    EOF

    runHook postInstall
  '';

  meta = with lib; {
    description = "Apache Commons Lang 2.x";
    homepage = "https://commons.apache.org/proper/commons-lang/";
    license = licenses.asl20;
    platforms = platforms.unix;
  };
})
