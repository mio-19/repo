{
  asm_6_2,
  asm_tree_6_2,
  fetchurl,
  jdk25_headless,
  lib,
  stdenv,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "asm-commons";
  version = "6.2";

  src = fetchurl {
    url = "https://repo.maven.apache.org/maven2/org/ow2/asm/asm-commons/${finalAttrs.version}/asm-commons-${finalAttrs.version}-sources.jar";
    hash = "sha256-Gs3zkU9851ZcTTlHSe7yK4K/irrKKnTHfwLd8O6YtC0=";
  };

  pom = fetchurl {
    url = "https://repo.maven.apache.org/maven2/org/ow2/asm/asm-commons/${finalAttrs.version}/asm-commons-${finalAttrs.version}.pom";
    hash = "sha256-F8Ox8iIXcX5ivSzvllrWwwvg6/xGepEk32M3IkPxG18=";
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
      -cp "${asm_6_2}/asm-${asm_6_2.version}.jar:${asm_tree_6_2}/asm-tree-${asm_tree_6_2.version}.jar" \
      -d classes \
      @sources.txt

    (
      cd classes
      jar cf "$tmp/asm-commons-${finalAttrs.version}.jar" .
    )

    mkdir -p "$out"
    install -Dm644 "$tmp/asm-commons-${finalAttrs.version}.jar" "$out/asm-commons-${finalAttrs.version}.jar"
    install -Dm644 "$pom" "$out/asm-commons-${finalAttrs.version}.pom"

    runHook postInstall
  '';

  meta = with lib; {
    description = "ASM common bytecode adapters";
    homepage = "https://asm.ow2.io/";
    license = licenses.bsd3;
    platforms = platforms.unix;
  };
})
