{
  fetchurl,
  jdk8_headless,
  lib,
  stdenv,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "antlr";
  version = "2.7.7";

  src = fetchurl {
    url = "https://www.antlr2.org/download/antlr-${finalAttrs.version}.tar.gz";
    hash = "sha256-hTrrAhrvdYa9op50prAwBry1ZadVyGtmAy2Owxtn27k=";
  };

  pom = fetchurl {
    url = "https://repo.maven.apache.org/maven2/antlr/antlr/${finalAttrs.version}/antlr-${finalAttrs.version}.pom";
    hash = "sha256-EA95O6J/i05CBO20YXHr825U4PlM/AJSf+oHoLsfzrc=";
  };

  nativeBuildInputs = [ jdk8_headless ];

  dontConfigure = true;

  buildPhase = ''
    runHook preBuild

    mkdir -p classes
    find antlr -name '*.java' ! -path 'antlr/preprocessor/JavaCharFormatter.java' | sort > sources.txt
    javac -source 1.4 -target 1.4 -encoding ISO-8859-1 -d classes @sources.txt

    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall

    (
      cd classes
      jar cf "$TMPDIR/antlr-${finalAttrs.version}.jar" .
    )

    mkdir -p "$out"
    install -Dm644 "$TMPDIR/antlr-${finalAttrs.version}.jar" "$out/antlr-${finalAttrs.version}.jar"
    install -Dm644 "$pom" "$out/antlr-${finalAttrs.version}.pom"

    runHook postInstall
  '';

  meta = with lib; {
    description = "ANother Tool for Language Recognition";
    homepage = "https://www.antlr2.org/";
    license = licenses.publicDomain;
    platforms = platforms.unix;
  };
})
