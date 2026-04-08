{
  fetchurl,
  jdk21,
  lib,
  stdenv,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "commons-logging";
  version = "1.2";

  src = fetchurl {
    url = "https://repo.maven.apache.org/maven2/commons-logging/commons-logging/${finalAttrs.version}/commons-logging-${finalAttrs.version}-sources.jar";
    hash = "sha256-RDR6z+WGBGFyjpyzMlHpc0W+Nvig39XFEwwXJVlFX0E=";
  };

  pom = fetchurl {
    url = "https://repo.maven.apache.org/maven2/commons-logging/commons-logging/${finalAttrs.version}/commons-logging-${finalAttrs.version}.pom";
    hash = "sha256-yRq1qlcNhvb9B8wVjsa8LFAIBAKXLukXn+JBAHOfuyA=";
  };

  nativeBuildInputs = [ jdk21 ];

  dontConfigure = true;
  dontUnpack = true;

  installPhase = ''
    runHook preInstall

    tmp="$(mktemp -d)"
    trap 'rm -rf "$tmp"' EXIT
    cd "$tmp"
    ${jdk21}/bin/jar xf "$src"

    mkdir -p classes
    find . -name '*.java' \
      ! -path './org/apache/commons/logging/impl/AvalonLogger.java' \
      ! -path './org/apache/commons/logging/impl/Log4JLogger.java' \
      ! -path './org/apache/commons/logging/impl/LogKitLogger.java' \
      ! -path './org/apache/commons/logging/impl/ServletContextCleaner.java' \
      | sort > sources.txt
    ${jdk21}/bin/javac --release 8 -d classes @sources.txt

    while IFS= read -r path; do
      install -Dm644 "$path" "classes/$path"
    done < <(find . -type f ! -name '*.java' ! -name 'sources.txt' ! -path './META-INF/maven/*' | sort)

    (
      cd classes
      ${jdk21}/bin/jar cf "$tmp/commons-logging-${finalAttrs.version}.jar" .
    )

    mkdir -p "$out"
    install -Dm644 "$tmp/commons-logging-${finalAttrs.version}.jar" "$out/commons-logging-${finalAttrs.version}.jar"
    install -Dm644 "$pom" "$out/commons-logging-${finalAttrs.version}.pom"

    runHook postInstall
  '';

  meta = with lib; {
    description = "Apache Commons Logging";
    homepage = "https://commons.apache.org/proper/commons-logging/";
    license = licenses.asl20;
    platforms = platforms.unix;
  };
})
