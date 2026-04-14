{
  fetchurl,
  jdk25_headless,
  lib,
  stdenv,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "commons-io";
  version = "2.6";

  src = fetchurl {
    url = "https://repo.maven.apache.org/maven2/commons-io/commons-io/${finalAttrs.version}/commons-io-${finalAttrs.version}-sources.jar";
    hash = "sha256-cbwlHrS9ARtgtc5q3I9HPeEOSFEgekDBRDRgSyiLMb8=";
  };

  pom = fetchurl {
    url = "https://repo.maven.apache.org/maven2/commons-io/commons-io/${finalAttrs.version}/commons-io-${finalAttrs.version}.pom";
    hash = "sha256-DCOGOJOiKR9aev29jRWSOzlIr9h+Vj+jQc3Pbq4zimA=";
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
    find org -name '*.java' | sort > sources.txt
    javac --release 8 -d classes @sources.txt

    (
      cd classes
      jar cf "$tmp/commons-io-${finalAttrs.version}.jar" .
    )

    mkdir -p "$out"
    install -Dm644 "$tmp/commons-io-${finalAttrs.version}.jar" "$out/commons-io-${finalAttrs.version}.jar"
    install -Dm644 "$pom" "$out/commons-io-${finalAttrs.version}.pom"

    runHook postInstall
  '';

  meta = with lib; {
    description = "Apache Commons IO library";
    homepage = "https://commons.apache.org/proper/commons-io/";
    license = licenses.asl20;
    platforms = platforms.unix;
  };
})
