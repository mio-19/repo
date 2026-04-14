{
  fetchFromGitHub,
  jdk21_headless,
  lib,
  stdenv,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "commons-cli";
  version = "1.2";

  src = fetchFromGitHub {
    owner = "apache";
    repo = "commons-cli";
    tag = "cli-${finalAttrs.version}";
    hash = "sha256-vODlZkSWJ7LKAfJaQxzx9ZnD3URj9reezvirS91kOLA=";
  };

  nativeBuildInputs = [ jdk21_headless ];

  dontConfigure = true;
  dontUnpack = true;

  installPhase = ''
    runHook preInstall

    tmp="$(mktemp -d)"
    
    cd "$tmp"

    mkdir -p classes
    find "${finalAttrs.src}/src/java" -name '*.java' | sort > sources.txt
    javac --release 8 -d classes @sources.txt

    (
      cd classes
      jar cf "$tmp/commons-cli-${finalAttrs.version}.jar" .
    )

    mkdir -p "$out"
    install -Dm644 "$tmp/commons-cli-${finalAttrs.version}.jar" "$out/commons-cli-${finalAttrs.version}.jar"
    install -Dm644 "${finalAttrs.src}/pom.xml" "$out/commons-cli-${finalAttrs.version}.pom"

    runHook postInstall
  '';

  meta = with lib; {
    description = "Apache Commons CLI";
    homepage = "https://commons.apache.org/proper/commons-cli/";
    license = licenses.asl20;
    platforms = platforms.unix;
  };
})
