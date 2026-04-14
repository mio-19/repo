{
  fetchFromGitHub,
  jdk25_headless,
  lib,
  stdenv,
}:
{
  version,
  tag,
  hash,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "commons-codec";
  inherit version;

  src = fetchFromGitHub {
    owner = "apache";
    repo = "commons-codec";
    inherit tag hash;
  };

  nativeBuildInputs = [ jdk25_headless ];

  dontConfigure = true;
  dontUnpack = true;

  installPhase = ''
    runHook preInstall

    tmp="$(mktemp -d)"
    
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
