{
  fetchurl,
  jdk21,
  lib,
  stdenv,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "junit";
  version = "3.8.1";

  src = fetchurl {
    url = "https://repo1.maven.org/maven2/junit/junit/${finalAttrs.version}/junit-${finalAttrs.version}-sources.jar";
    hash = "sha256-ziUxkgk/sk2ucX6ltoY+Zwh0Fnls42bXpT+kZ7DRTq0=";
  };

  nativeBuildInputs = [ jdk21 ];

  dontConfigure = true;
  dontUnpack = true;

  installPhase = ''
    runHook preInstall

    tmp="$(mktemp -d)"
    trap 'rm -rf "$tmp"' EXIT
    mkdir -p "$tmp/src" "$tmp/classes"
    cd "$tmp/src"
    jar xf "${finalAttrs.src}"
    find . -name '*.java' | sort > "$tmp/sources.txt"
    javac --release 8 -encoding ISO-8859-1 -d "$tmp/classes" @"$tmp/sources.txt"

    (
      cd "$tmp/classes"
      jar cf "$tmp/junit-${finalAttrs.version}.jar" .
    )

    mkdir -p "$out"
    install -Dm644 "$tmp/junit-${finalAttrs.version}.jar" "$out/junit-${finalAttrs.version}.jar"
    cat > "$out/junit-${finalAttrs.version}.pom" <<EOF
    <project>
      <modelVersion>4.0.0</modelVersion>
      <groupId>junit</groupId>
      <artifactId>junit</artifactId>
      <version>${finalAttrs.version}</version>
    </project>
    EOF

    runHook postInstall
  '';

  meta = with lib; {
    description = "JUnit 3 testing framework";
    homepage = "https://junit.org/";
    license = licenses.cpl10;
    platforms = platforms.unix;
  };
})
