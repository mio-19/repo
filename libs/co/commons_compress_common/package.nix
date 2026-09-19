{
  fetchFromGitHub,
  jdk25_headless,
  lib,
  stdenv,
}:

# Common builder for Apache Commons Compress.
# Classpath jars (xz, brotli, commons-io, zstd-jni, asm, …) are supplied by
# the version package via `classpathJars`.
{
  version,
  tag,
  hash,
  classpathJars ? [ ],
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "commons-compress";
  inherit version;

  src = fetchFromGitHub {
    owner = "apache";
    repo = "commons-compress";
    inherit tag hash;
  };

  nativeBuildInputs = [ jdk25_headless ];

  dontConfigure = true;
  dontUnpack = true;

  installPhase = ''
    runHook preInstall

    tmp="$(mktemp -d)"

    cd "$tmp"

    mkdir -p classes
    find "${finalAttrs.src}/src/main/java" -name '*.java' ! -name 'module-info.java' | sort > sources.txt
    javac --release 8 \
      -encoding ISO-8859-1 \
      -cp "${lib.concatStringsSep ":" classpathJars}" \
      -d classes \
      @sources.txt
    if [ -f "${finalAttrs.src}/src/main/java/module-info.java" ]; then
      javac --release 9 -encoding ISO-8859-1 -cp classes -d classes "${finalAttrs.src}/src/main/java/module-info.java"
    fi

    if [ -d "${finalAttrs.src}/src/main/resources" ]; then
      while IFS= read -r path; do
        rel_path="$(realpath --relative-to="${finalAttrs.src}/src/main/resources" "$path")"
        install -Dm644 "$path" "classes/$rel_path"
      done < <(find "${finalAttrs.src}/src/main/resources" -type f | sort)
    fi

    (
      cd classes
      jar cf "$tmp/commons-compress-${finalAttrs.version}.jar" .
    )

    mkdir -p "$out"
    install -Dm644 "$tmp/commons-compress-${finalAttrs.version}.jar" "$out/commons-compress-${finalAttrs.version}.jar"
    install -Dm644 "${finalAttrs.src}/pom.xml" "$out/commons-compress-${finalAttrs.version}.pom"

    runHook postInstall
  '';

  meta = with lib; {
    description = "Apache Commons Compress";
    homepage = "https://commons.apache.org/proper/commons-compress/";
    license = licenses.asl20;
    platforms = platforms.unix;
  };
})
