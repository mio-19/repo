{
  fetchFromGitHub,
  jdk21,
  lib,
  stdenv,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "commons-logging";
  version = "1.2";

  src = fetchFromGitHub {
    owner = "apache";
    repo = "commons-logging";
    tag = "LOGGING_1_2";
    hash = "sha256-iLslo01M2tp9Ls5yPBRBcA+1w2sp2doHJRYlMkUfzSg=";
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
    find "${finalAttrs.src}/src/main/java" -name '*.java' \
      ! -path '*/org/apache/commons/logging/impl/AvalonLogger.java' \
      ! -path '*/org/apache/commons/logging/impl/Log4JLogger.java' \
      ! -path '*/org/apache/commons/logging/impl/LogKitLogger.java' \
      ! -path '*/org/apache/commons/logging/impl/ServletContextCleaner.java' \
      | sort > sources.txt
    ${jdk21}/bin/javac --release 8 -d classes @sources.txt

    if [ -d "${finalAttrs.src}/src/main/resources" ]; then
      while IFS= read -r path; do
        rel_path="$(realpath --relative-to="${finalAttrs.src}/src/main/resources" "$path")"
        install -Dm644 "$path" "classes/$rel_path"
      done < <(find "${finalAttrs.src}/src/main/resources" -type f | sort)
    fi

    (
      cd classes
      ${jdk21}/bin/jar cf "$tmp/commons-logging-${finalAttrs.version}.jar" .
    )

    mkdir -p "$out"
    install -Dm644 "$tmp/commons-logging-${finalAttrs.version}.jar" "$out/commons-logging-${finalAttrs.version}.jar"
    install -Dm644 "${finalAttrs.src}/pom.xml" "$out/commons-logging-${finalAttrs.version}.pom"

    runHook postInstall
  '';

  doInstallCheck = true;

  installCheckPhase = ''
    runHook preInstallCheck

    cat > CommonsLoggingSmoke.java <<'EOF'
    public final class CommonsLoggingSmoke {
      public static void main(String[] args) {
        org.apache.commons.logging.Log log =
            org.apache.commons.logging.LogFactory.getLog("commons-logging-smoke");
        if (log == null) {
          throw new AssertionError("LogFactory returned null");
        }
      }
    }
    EOF
    ${jdk21}/bin/javac --release 8 -cp "$out/commons-logging-${finalAttrs.version}.jar" CommonsLoggingSmoke.java
    ${jdk21}/bin/java -cp "$out/commons-logging-${finalAttrs.version}.jar:." CommonsLoggingSmoke

    runHook postInstallCheck
  '';

  meta = with lib; {
    description = "Apache Commons Logging";
    homepage = "https://commons.apache.org/proper/commons-logging/";
    license = licenses.asl20;
    platforms = platforms.unix;
  };
})
