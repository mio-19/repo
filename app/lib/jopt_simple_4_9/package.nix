{
  fetchFromGitHub,
  jdk21_headless,
  lib,
  stdenv,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "jopt-simple";
  version = "4.9";

  src = fetchFromGitHub {
    owner = "pholser";
    repo = "jopt-simple";
    tag = "jopt-simple-${finalAttrs.version}";
    hash = "sha256-yhje4nHwesaMcgJfa44TywE7dzBn5TnaMZmo269er3s=";
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
    find "${finalAttrs.src}/src/main/java" -name '*.java' | sort > sources.txt
    javac --release 8 -d classes @sources.txt
    cp -R "${finalAttrs.src}/src/main/resources"/. classes/

    (
      cd classes
      jar cf "$tmp/jopt-simple-${finalAttrs.version}.jar" .
    )

    mkdir -p "$out"
    install -Dm644 "$tmp/jopt-simple-${finalAttrs.version}.jar" "$out/jopt-simple-${finalAttrs.version}.jar"
    install -Dm644 "${finalAttrs.src}/pom.xml" "$out/jopt-simple-${finalAttrs.version}.pom"

    runHook postInstall
  '';

  meta = with lib; {
    description = "Java command line option parser";
    homepage = "https://github.com/pholser/jopt-simple";
    license = licenses.mit;
    platforms = platforms.unix;
  };
})
