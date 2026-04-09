{
  fetchurl,
  jdk21,
  lib,
  stdenv,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "jopt-simple";
  version = "2.4.1";

  src = fetchurl {
    url = "https://repo1.maven.org/maven2/net/sf/jopt-simple/jopt-simple/${finalAttrs.version}/jopt-simple-${finalAttrs.version}-sources.jar";
    hash = "sha256-Y5rhpxMtZqCq6xEB2sw5SBwMPycfh8+IWlNCtBFDhRY=";
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
    ${jdk21}/bin/jar xf "${finalAttrs.src}"
    find . -name '*.java' | sort > "$tmp/sources.txt"
    ${jdk21}/bin/javac --release 8 -encoding ISO-8859-1 -d "$tmp/classes" @"$tmp/sources.txt"

    (
      cd "$tmp/classes"
      ${jdk21}/bin/jar cf "$tmp/jopt-simple-${finalAttrs.version}.jar" .
    )

    mkdir -p "$out"
    install -Dm644 "$tmp/jopt-simple-${finalAttrs.version}.jar" "$out/jopt-simple-${finalAttrs.version}.jar"
    cat > "$out/jopt-simple-${finalAttrs.version}.pom" <<EOF
    <project>
      <modelVersion>4.0.0</modelVersion>
      <groupId>net.sf.jopt-simple</groupId>
      <artifactId>jopt-simple</artifactId>
      <version>${finalAttrs.version}</version>
    </project>
    EOF

    runHook postInstall
  '';

  meta = with lib; {
    description = "Java command line option parser";
    homepage = "https://jopt-simple.github.io/jopt-simple/";
    license = licenses.mit;
    platforms = platforms.unix;
  };
})
