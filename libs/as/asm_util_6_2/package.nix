{
  asm_6_2,
  asm_tree_6_2,
  asm_analysis_6_2,
  fetchurl,
  jdk25_headless,
  lib,
  stdenv,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "asm-util";
  version = "6.2";

  src = fetchurl {
    url = "https://repo.maven.apache.org/maven2/org/ow2/asm/asm-util/${finalAttrs.version}/asm-util-${finalAttrs.version}-sources.jar";
    hash = "sha256-P63szG2lP5w4nMjJrBNZglZ7z/tq7YUial99fOu+a9c=";
  };

  pom = fetchurl {
    url = "https://repo.maven.apache.org/maven2/org/ow2/asm/asm-util/${finalAttrs.version}/asm-util-${finalAttrs.version}.pom";
    hash = "sha256-SZCdxfl3C5CuGA0PLoXC5kQ7ezmoRFzcKL91f2EX4sA=";
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
      -cp "${asm_6_2}/asm-${asm_6_2.version}.jar:${asm_tree_6_2}/asm-tree-${asm_tree_6_2.version}.jar:${asm_analysis_6_2}/asm-analysis-${asm_analysis_6_2.version}.jar" \
      -d classes \
      @sources.txt

    (
      cd classes
      jar cf "$tmp/asm-util-${finalAttrs.version}.jar" .
    )

    mkdir -p "$out"
    install -Dm644 "$tmp/asm-util-${finalAttrs.version}.jar" "$out/asm-util-${finalAttrs.version}.jar"
    install -Dm644 "$pom" "$out/asm-util-${finalAttrs.version}.pom"

    runHook postInstall
  '';

  meta = with lib; {
    description = "ASM utility classes";
    homepage = "https://asm.ow2.io/";
    license = licenses.bsd3;
    platforms = platforms.unix;
  };
})
