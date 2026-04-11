{
  fetchFromGitHub,
  jdk8_headless,
  lib,
  stdenv,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "commons-lang";
  version = "2.5";

  src = fetchFromGitHub {
    owner = "apache";
    repo = "commons-lang";
    tag = "LANG_${builtins.replaceStrings [ "." ] [ "_" ] finalAttrs.version}";
    hash = "sha256-REChX/73o930WGeVROltgnCa75jOZOsocypimriKp/E=";
  };

  nativeBuildInputs = [ jdk8_headless ];

  dontConfigure = true;
  dontUnpack = true;

  installPhase = ''
    runHook preInstall

    tmp="$(mktemp -d)"
    trap 'rm -rf "$tmp"' EXIT
    cd "$tmp"

    mkdir -p classes
    find "${finalAttrs.src}/src/main/java" -name '*.java' | sort > sources.txt
    javac -source 1.4 -target 1.4 -encoding ISO-8859-1 -d classes @sources.txt

    (
      cd classes
      jar cf "$tmp/commons-lang-${finalAttrs.version}.jar" .
    )

    mkdir -p "$out"
    install -Dm644 "$tmp/commons-lang-${finalAttrs.version}.jar" "$out/commons-lang-${finalAttrs.version}.jar"
    install -Dm644 "${finalAttrs.src}/pom.xml" "$out/commons-lang-${finalAttrs.version}.pom"

    runHook postInstall
  '';

  meta = with lib; {
    description = "Apache Commons Lang";
    homepage = "https://commons.apache.org/proper/commons-lang/";
    license = licenses.asl20;
    platforms = platforms.unix;
  };
})
