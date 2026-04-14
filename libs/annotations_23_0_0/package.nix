{
  fetchFromGitHub,
  fetchurl,
  jdk25_headless,
  lib,
  stdenv,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "annotations";
  version = "23.0.0";

  src = fetchFromGitHub {
    owner = "JetBrains";
    repo = "java-annotations";
    tag = finalAttrs.version;
    hash = "sha256-pMI7q9UzwpZaobaAYC4DLF2q//083l22X9Fjm+SnNWA=";
  };

  pomFile = fetchurl {
    url = "https://repo.maven.apache.org/maven2/org/jetbrains/annotations/23.0.0/annotations-23.0.0.pom";
    hash = "sha256-yUkPZVEyMo3yz7z990P1P8ORbWwdEENxdabKbjpndxw=";
  };

  nativeBuildInputs = [ jdk25_headless ];

  dontConfigure = true;
  dontUnpack = true;

  installPhase = ''
    runHook preInstall

    tmp="$(mktemp -d)"
    
    cd "$tmp"

    mkdir -p classes
    find "${finalAttrs.src}/common/src/main/java" "${finalAttrs.src}/java8/src/main/java" -name '*.java' | sort > sources.txt
    javac --release 8 -encoding UTF-8 -d classes @sources.txt

    (
      cd classes
      jar cf "$tmp/annotations-${finalAttrs.version}.jar" .
    )

    mkdir -p "$out"
    install -Dm644 "$tmp/annotations-${finalAttrs.version}.jar" "$out/annotations-${finalAttrs.version}.jar"
    install -Dm644 "${finalAttrs.pomFile}" "$out/annotations-${finalAttrs.version}.pom"

    runHook postInstall
  '';

  meta = with lib; {
    description = "JetBrains Java annotations";
    homepage = "https://github.com/JetBrains/java-annotations";
    license = licenses.asl20;
    platforms = platforms.unix;
  };
})
