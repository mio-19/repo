{
  fetchurl,
  jdk25_headless,
  lib,
  stdenv,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "asm";
  version = "6.2";

  src = fetchurl {
    url = "https://repo.maven.apache.org/maven2/org/ow2/asm/asm/${finalAttrs.version}/asm-${finalAttrs.version}-sources.jar";
    hash = "sha256-dx4o84tK3J+BcmLWaj1dVq4cEx0jhbIIxhNlX77gX0A=";
  };

  pom = fetchurl {
    url = "https://repo.maven.apache.org/maven2/org/ow2/asm/asm/${finalAttrs.version}/asm-${finalAttrs.version}.pom";
    hash = "sha256-kuxjP5P5yE3LCHp53xOVz+8HvldAds6usxWeCWtNRkM=";
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
      jar cf "$tmp/asm-${finalAttrs.version}.jar" .
    )

    mkdir -p "$out"
    install -Dm644 "$tmp/asm-${finalAttrs.version}.jar" "$out/asm-${finalAttrs.version}.jar"
    install -Dm644 "$pom" "$out/asm-${finalAttrs.version}.pom"

    runHook postInstall
  '';

  meta = with lib; {
    description = "Java bytecode manipulation framework";
    homepage = "https://asm.ow2.io/";
    license = licenses.bsd3;
    platforms = platforms.unix;
  };
})
