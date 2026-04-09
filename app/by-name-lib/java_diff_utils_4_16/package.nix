{
  fetchFromGitHub,
  jdk21_headless,
  lib,
  stdenv,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "java-diff-utils";
  version = "4.16";

  src = fetchFromGitHub {
    owner = "java-diff-utils";
    repo = "java-diff-utils";
    tag = "java-diff-utils-parent-${finalAttrs.version}";
    hash = "sha256-H2F+20URht/Va3EP1Eztq1cjpCfNG77ePRRq1mrYvGY=";
  };

  nativeBuildInputs = [ jdk21_headless ];

  dontConfigure = true;
  dontUnpack = true;

  installPhase = ''
    runHook preInstall

    tmp="$(mktemp -d)"
    trap 'rm -rf "$tmp"' EXIT
    cd "$tmp"

    mkdir -p classes
    find "${finalAttrs.src}/java-diff-utils/src/main/java" -name '*.java' | sort > sources.txt
    javac --release 8 -d classes @sources.txt

    (
      cd classes
      jar cf "$tmp/java-diff-utils-${finalAttrs.version}.jar" .
    )

    mkdir -p "$out"
    install -Dm644 "$tmp/java-diff-utils-${finalAttrs.version}.jar" "$out/java-diff-utils-${finalAttrs.version}.jar"
    install -Dm644 "${finalAttrs.src}/java-diff-utils/pom.xml" "$out/java-diff-utils-${finalAttrs.version}.pom"
    install -Dm644 "${finalAttrs.src}/pom.xml" "$out/java-diff-utils-parent-${finalAttrs.version}.pom"

    runHook postInstall
  '';

  meta = with lib; {
    description = "Diff utility library for Java";
    homepage = "https://github.com/java-diff-utils/java-diff-utils";
    license = licenses.asl20;
    platforms = platforms.unix;
  };
})
