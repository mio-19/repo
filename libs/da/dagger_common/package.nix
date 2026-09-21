{
  fetchurl,
  jdk25_headless,
  lib,
  stdenv,
}:

# Common builder for the Dagger dependency-injection runtime jar.
# Built from the Maven Central sources jar (the GitHub repo is a multi-module
# Gradle monorepo; the published sources artifact is the practical unit).
{
  version,
  srcHash,
  pomHash,
  classpathJars ? [ ],
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "dagger";
  inherit version;

  src = fetchurl {
    url = "https://repo.maven.apache.org/maven2/com/google/dagger/dagger/${finalAttrs.version}/dagger-${finalAttrs.version}-sources.jar";
    hash = srcHash;
  };

  pom = fetchurl {
    url = "https://repo.maven.apache.org/maven2/com/google/dagger/dagger/${finalAttrs.version}/dagger-${finalAttrs.version}.pom";
    hash = pomHash;
  };

  nativeBuildInputs = [ jdk25_headless ];

  dontConfigure = true;
  dontUnpack = true;

  installPhase = ''
    runHook preInstall

    tmp="$(mktemp -d)"

    cd "$tmp"
    jar xf "$src"

    mkdir -p classes
    find . -name '*.java' ! -name 'module-info.java' | sort > sources.txt
    javac --release 8 \
      -cp "${lib.concatStringsSep ":" classpathJars}" \
      -d classes \
      @sources.txt

    while IFS= read -r path; do
      rel_path="$(realpath --relative-to="$tmp" "$path")"
      install -Dm644 "$path" "classes/$rel_path"
    done < <(find . -type f ! -name '*.java' ! -path './classes/*' ! -name 'sources.txt' 2>/dev/null | sort)

    (
      cd classes
      jar cf "$tmp/dagger-${finalAttrs.version}.jar" .
    )

    mkdir -p "$out"
    install -Dm644 "$tmp/dagger-${finalAttrs.version}.jar" "$out/dagger-${finalAttrs.version}.jar"
    install -Dm644 "$pom" "$out/dagger-${finalAttrs.version}.pom"

    runHook postInstall
  '';

  meta = with lib; {
    description = "A fast dependency injector for Java and Android";
    homepage = "https://dagger.dev/";
    license = licenses.asl20;
    platforms = platforms.unix;
  };
})
