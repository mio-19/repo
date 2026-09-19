{
  asm_6_2,
  asm_tree_6_2,
  fetchurl,
  jdk25_headless,
  lib,
  stdenv,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "asm-analysis";
  version = "6.2";

  src = fetchurl {
    url = "https://repo.maven.apache.org/maven2/org/ow2/asm/asm-analysis/${finalAttrs.version}/asm-analysis-${finalAttrs.version}-sources.jar";
    hash = "sha256-u57PPXh3hmB6Y7zkKW/kqAYZKPABq6IOATDeFNB2yPU=";
  };

  pom = fetchurl {
    url = "https://repo.maven.apache.org/maven2/org/ow2/asm/asm-analysis/${finalAttrs.version}/asm-analysis-${finalAttrs.version}.pom";
    hash = "sha256-sSaPjpHGS/ScZ6OYdFbPW9OmWoYtXYNqjni0469o7bw=";
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
      jar cf "$tmp/asm-analysis-${finalAttrs.version}.jar" .
    )

    mkdir -p "$out"
    install -Dm644 "$tmp/asm-analysis-${finalAttrs.version}.jar" "$out/asm-analysis-${finalAttrs.version}.jar"
    install -Dm644 "$pom" "$out/asm-analysis-${finalAttrs.version}.pom"

    runHook postInstall
  '';

  meta = with lib; {
    description = "ASM analysis API";
    homepage = "https://asm.ow2.io/";
    license = licenses.bsd3;
    platforms = platforms.unix;
  };
})
