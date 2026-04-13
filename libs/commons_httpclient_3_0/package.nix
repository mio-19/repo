{
  commons_codec_1_2,
  commons_logging_1_0_3,
  fetchurl,
  jdk25_headless,
  lib,
  stdenv,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "commons-httpclient";
  version = "3.0";

  src = fetchurl {
    url = "https://repo1.maven.org/maven2/commons-httpclient/commons-httpclient/3.0/commons-httpclient-3.0-sources.jar";
    hash = "sha256-muWdaj/3rSDLNrlGsceoDbUSSCXXAf+O3kRkxCLsJR4=";
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
    javac \
      --release 8 \
      -encoding ISO-8859-1 \
      -cp "${commons_logging_1_0_3}/commons-logging-${commons_logging_1_0_3.version}.jar:${commons_codec_1_2}/commons-codec-${commons_codec_1_2.version}.jar" \
      -d "$tmp/classes" \
      @"$tmp/sources.txt"

    (
      cd "$tmp/classes"
      jar cf "$tmp/commons-httpclient-${finalAttrs.version}.jar" .
    )

    mkdir -p "$out"
    install -Dm644 "$tmp/commons-httpclient-${finalAttrs.version}.jar" "$out/commons-httpclient-${finalAttrs.version}.jar"
    cat > "$out/commons-httpclient-${finalAttrs.version}.pom" <<EOF
    <project>
      <modelVersion>4.0.0</modelVersion>
      <groupId>commons-httpclient</groupId>
      <artifactId>commons-httpclient</artifactId>
      <version>${finalAttrs.version}</version>
    </project>
    EOF

    runHook postInstall
  '';

  meta = with lib; {
    description = "Apache Commons HttpClient";
    homepage = "https://hc.apache.org/httpclient-legacy/";
    license = licenses.asl20;
    platforms = platforms.unix;
  };
})
