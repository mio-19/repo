{
  fetchFromGitHub,
  jdk21,
  lib,
  stdenv,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "flatbuffers-java";
  version = "1.12.0";

  src = fetchFromGitHub {
    owner = "google";
    repo = "flatbuffers";
    tag = "v${finalAttrs.version}";
    hash = "sha256-L1B5Y/c897Jg9fGwT2J3+vaXsZ+lfXnskp8Gto1p/Tg=";
  };

  nativeBuildInputs = [ jdk21 ];

  dontConfigure = true;
  dontUnpack = true;

  installPhase = ''
    runHook preInstall

    tmp="$(mktemp -d)"
    trap 'rm -rf "$tmp"' EXIT
    cd "$tmp"

    mkdir -p classes
    find "${finalAttrs.src}/java" -name '*.java' | sort > sources.txt
    javac --release 8 -encoding UTF-8 -d classes @sources.txt

    (
      cd classes
      jar cf "$tmp/flatbuffers-java-${finalAttrs.version}.jar" .
    )

    mkdir -p "$out"
    install -Dm644 "$tmp/flatbuffers-java-${finalAttrs.version}.jar" "$out/flatbuffers-java-${finalAttrs.version}.jar"
    install -Dm644 "${finalAttrs.src}/pom.xml" "$out/flatbuffers-java-${finalAttrs.version}.pom"

    runHook postInstall
  '';

  meta = with lib; {
    description = "FlatBuffers Java API";
    homepage = "https://github.com/google/flatbuffers";
    license = licenses.asl20;
    platforms = platforms.unix;
  };
})
