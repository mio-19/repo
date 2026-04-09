{
  fetchFromGitHub,
  jdk21,
  lib,
  stdenv,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "commons-logging";
  version = "1.0.3";

  src = fetchFromGitHub {
    owner = "apache";
    repo = "commons-logging";
    tag = "LOGGING_1_0_3";
    hash = "sha256-+acvWKFRD2jSpnLl5i3EJUDD4V+SyVP0ydcxG8HQ+JY=";
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
    find "${finalAttrs.src}/src/java" -name '*.java' \
      ! -path '*/org/apache/commons/logging/impl/AvalonLogger.java' \
      ! -path '*/org/apache/commons/logging/impl/Log4JCategoryLog.java' \
      ! -path '*/org/apache/commons/logging/impl/Log4JLogger.java' \
      ! -path '*/org/apache/commons/logging/impl/Log4jFactory.java' \
      ! -path '*/org/apache/commons/logging/impl/LogKitLogger.java' \
      ! -path '*/org/apache/commons/logging/impl/ServletContextCleaner.java' \
      | sort > sources.txt
    ${jdk21}/bin/javac --release 8 -d classes @sources.txt

    (
      cd classes
      ${jdk21}/bin/jar cf "$tmp/commons-logging-${finalAttrs.version}.jar" .
    )

    mkdir -p "$out"
    install -Dm644 "$tmp/commons-logging-${finalAttrs.version}.jar" "$out/commons-logging-${finalAttrs.version}.jar"
    cat > "$out/commons-logging-${finalAttrs.version}.pom" <<EOF
    <project>
      <modelVersion>4.0.0</modelVersion>
      <groupId>commons-logging</groupId>
      <artifactId>commons-logging</artifactId>
      <version>${finalAttrs.version}</version>
    </project>
    EOF

    runHook postInstall
  '';

  meta = with lib; {
    description = "Apache Commons Logging";
    homepage = "https://commons.apache.org/proper/commons-logging/";
    license = licenses.asl20;
    platforms = platforms.unix;
  };
})
