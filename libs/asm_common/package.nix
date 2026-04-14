{
  fetchurl,
  jdk25_headless,
  lib,
  stdenv,
}:
{
  artifactId,
  version,
  srcHash,
  pomHash,
  classpath ? [ ],
}:

stdenv.mkDerivation (finalAttrs: {
  pname = artifactId;
  inherit version;

  src = fetchurl {
    url = "https://repo.maven.apache.org/maven2/org/ow2/asm/${artifactId}/${finalAttrs.version}/${artifactId}-${finalAttrs.version}-sources.jar";
    hash = srcHash;
  };

  pom = fetchurl {
    url = "https://repo.maven.apache.org/maven2/org/ow2/asm/${artifactId}/${finalAttrs.version}/${artifactId}-${finalAttrs.version}.pom";
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
    find org -name '*.java' > sources.txt
    javac --release 8 \
      ${lib.optionalString (classpath != [ ]) "-cp ${lib.concatStringsSep ":" classpath}"} \
      -d classes \
      @sources.txt

    (
      cd classes
      jar cf "$tmp/${artifactId}-${finalAttrs.version}.jar" .
    )

    mkdir -p "$out"
    install -Dm644 "$tmp/${artifactId}-${finalAttrs.version}.jar" "$out/${artifactId}-${finalAttrs.version}.jar"
    install -Dm644 "$pom" "$out/${artifactId}-${finalAttrs.version}.pom"

    runHook postInstall
  '';

  meta = with lib; {
    description = "Java bytecode manipulation framework";
    homepage = "https://asm.ow2.io/";
    license = licenses.bsd3;
    platforms = platforms.unix;
  };
})
