{
  fetchurl,
  jdk25_headless,
  lib,
  stdenv,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "servlet-api";
  version = "2.5";

  src = fetchurl {
    url = "https://repo1.maven.org/maven2/javax/servlet/servlet-api/2.5/servlet-api-2.5-sources.jar";
    hash = "sha256-3Vs12ln/BKv452P/QJuWN14cQ/sRbSZYDGgrtxWk/Fo=";
  };

  nativeBuildInputs = [ jdk25_headless ];

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
      jar cf "$tmp/servlet-api-${finalAttrs.version}.jar" .
    )

    mkdir -p "$out"
    install -Dm644 "$tmp/servlet-api-${finalAttrs.version}.jar" "$out/servlet-api-${finalAttrs.version}.jar"
    cat > "$out/servlet-api-${finalAttrs.version}.pom" <<EOF
    <project>
      <modelVersion>4.0.0</modelVersion>
      <groupId>javax.servlet</groupId>
      <artifactId>servlet-api</artifactId>
      <version>${finalAttrs.version}</version>
    </project>
    EOF

    runHook postInstall
  '';

  meta = with lib; {
    description = "Java Servlet API";
    homepage = "https://jakarta.ee/specifications/servlet/";
    license = licenses.cddl;
    platforms = platforms.unix;
  };
})
