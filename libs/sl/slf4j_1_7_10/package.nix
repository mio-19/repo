{
  fetchFromGitHub,
  jdk21_headless,
  lib,
  stdenv,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "slf4j";
  version = "1.7.10";

  src = fetchFromGitHub {
    owner = "qos-ch";
    repo = "slf4j";
    tag = "v_${finalAttrs.version}";
    hash = "sha256-48uAtuoOGb83oE0PJd6ryc+UCvi89LriKGR130vAz1s=";
  };

  nativeBuildInputs = [ jdk21_headless ];

  dontConfigure = true;
  dontUnpack = true;

  installPhase = ''
    runHook preInstall

    tmp="$(mktemp -d)"

    cd "$tmp"

    mkdir -p api-classes jcl-classes jul-classes log4j-classes simple-classes
    find "${finalAttrs.src}/slf4j-api/src/main/java" -name '*.java' | sort > api-sources.txt
    javac --release 8 -d api-classes @api-sources.txt
    rm -rf api-classes/org/slf4j/impl

    find "${finalAttrs.src}/jcl-over-slf4j/src/main/java" -name '*.java' | sort > jcl-sources.txt
    javac --release 8 -cp api-classes -d jcl-classes @jcl-sources.txt

    find "${finalAttrs.src}/jul-to-slf4j/src/main/java" -name '*.java' | sort > jul-sources.txt
    javac --release 8 -cp api-classes -d jul-classes @jul-sources.txt

    find "${finalAttrs.src}/log4j-over-slf4j/src/main/java" -name '*.java' | sort > log4j-sources.txt
    javac --release 8 -cp api-classes -d log4j-classes @log4j-sources.txt

    find "${finalAttrs.src}/slf4j-simple/src/main/java" -name '*.java' | sort > simple-sources.txt
    javac --release 8 -cp api-classes -d simple-classes @simple-sources.txt

    for artifactId in slf4j-api jcl-over-slf4j jul-to-slf4j log4j-over-slf4j slf4j-simple; do
      case "$artifactId" in
        slf4j-api) classes_dir="$tmp/api-classes" ;;
        jcl-over-slf4j) classes_dir="$tmp/jcl-classes" ;;
        jul-to-slf4j) classes_dir="$tmp/jul-classes" ;;
        log4j-over-slf4j) classes_dir="$tmp/log4j-classes" ;;
        slf4j-simple) classes_dir="$tmp/simple-classes" ;;
      esac
      (
        cd "$classes_dir"
        jar cf "$tmp/$artifactId-${finalAttrs.version}.jar" .
      )
    done

    mkdir -p "$out"
    for artifactId in slf4j-api jcl-over-slf4j jul-to-slf4j log4j-over-slf4j slf4j-simple; do
      install -Dm644 "$tmp/$artifactId-${finalAttrs.version}.jar" "$out/$artifactId-${finalAttrs.version}.jar"
      install -Dm644 "${finalAttrs.src}/$artifactId/pom.xml" "$out/$artifactId-${finalAttrs.version}.pom"
    done
    install -Dm644 "${finalAttrs.src}/pom.xml" "$out/slf4j-parent-${finalAttrs.version}.pom"

    runHook postInstall
  '';

  meta = with lib; {
    description = "Simple Logging Facade for Java and bridges";
    homepage = "https://www.slf4j.org/";
    license = licenses.mit;
    platforms = platforms.unix;
  };
})
