{
  fetchFromGitHub,
  jdk21_headless,
  lib,
  stdenv,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "gson";
  version = "2.2.4";

  src = fetchFromGitHub {
    owner = "google";
    repo = "gson";
    tag = "gson-${finalAttrs.version}";
    hash = "sha256-K4asllY/EgpqYD6XYn7xyiYRiFhZCgRVKz3L+6sRVa4=";
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

    (
      cd classes
      jar cf "$tmp/gson-${finalAttrs.version}.jar" .
    )

    mkdir -p "$out"
    install -Dm644 "$tmp/gson-${finalAttrs.version}.jar" "$out/gson-${finalAttrs.version}.jar"
    install -Dm644 "${finalAttrs.src}/pom.xml" "$out/gson-${finalAttrs.version}.pom"

    runHook postInstall
  '';

  meta = with lib; {
    description = "Java serialization and deserialization library for JSON";
    homepage = "https://github.com/google/gson";
    license = licenses.asl20;
    platforms = platforms.unix;
  };
})
