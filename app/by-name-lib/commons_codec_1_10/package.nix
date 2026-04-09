{
  fetchFromGitHub,
  jdk21,
  lib,
  stdenv,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "commons-codec";
  version = "1.10";

  src = fetchFromGitHub {
    owner = "apache";
    repo = "commons-codec";
    tag = finalAttrs.version;
    hash = "sha256-3Nnrneb51U9zpLF7v3VwWvEHvXJa2SrOdhsUOnsXwyA=";
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
    find "${finalAttrs.src}/src/main/java" -name '*.java' | sort > sources.txt
    javac --release 8 -d classes @sources.txt

    while IFS= read -r path; do
      rel_path="$(realpath --relative-to="${finalAttrs.src}/src/main/resources" "$path")"
      install -Dm644 "$path" "classes/$rel_path"
    done < <(find "${finalAttrs.src}/src/main/resources" -type f | sort)

    (
      cd classes
      jar cf "$tmp/commons-codec-${finalAttrs.version}.jar" .
    )

    mkdir -p "$out"
    install -Dm644 "$tmp/commons-codec-${finalAttrs.version}.jar" "$out/commons-codec-${finalAttrs.version}.jar"
    install -Dm644 "${finalAttrs.src}/pom.xml" "$out/commons-codec-${finalAttrs.version}.pom"

    runHook postInstall
  '';

  meta = with lib; {
    description = "Apache Commons Codec";
    homepage = "https://commons.apache.org/proper/commons-codec/";
    license = licenses.asl20;
    platforms = platforms.unix;
  };
})
