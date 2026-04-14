{
  asm_6_2,
  fetchurl,
  jdk25_headless,
  lib,
  stdenv,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "asm-tree";
  version = "6.2";

  src = fetchurl {
    url = "https://repo.maven.apache.org/maven2/org/ow2/asm/asm-tree/${finalAttrs.version}/asm-tree-${finalAttrs.version}-sources.jar";
    hash = "sha256-s6d2aviB5e+ZxTHwyGKkDTO7p0E22qoy2izbUcj37l8=";
  };

  pom = fetchurl {
    url = "https://repo.maven.apache.org/maven2/org/ow2/asm/asm-tree/${finalAttrs.version}/asm-tree-${finalAttrs.version}.pom";
    hash = "sha256-4xQabu6pykJGeu/GeQejwQymywtTOTJ50aXMtSujRjI=";
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
    javac --release 8 -cp "${asm_6_2}/asm-${asm_6_2.version}.jar" -d classes @sources.txt

    (
      cd classes
      jar cf "$tmp/asm-tree-${finalAttrs.version}.jar" .
    )

    mkdir -p "$out"
    install -Dm644 "$tmp/asm-tree-${finalAttrs.version}.jar" "$out/asm-tree-${finalAttrs.version}.jar"
    install -Dm644 "$pom" "$out/asm-tree-${finalAttrs.version}.pom"

    runHook postInstall
  '';

  meta = with lib; {
    description = "ASM tree API";
    homepage = "https://asm.ow2.io/";
    license = licenses.bsd3;
    platforms = platforms.unix;
  };
})
