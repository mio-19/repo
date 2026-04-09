{
  fetchFromGitHub,
  jdk25,
  lib,
  stdenv,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "commons-io";
  version = "2.16.1";

  src = fetchFromGitHub {
    owner = "apache";
    repo = "commons-io";
    tag = "rel/commons-io-${finalAttrs.version}";
    hash = "sha256-BSTfju2X8TEIwDeFGrF98CVshZoscZLhv5XjG7YaxEE=";
  };

  nativeBuildInputs = [ jdk25 ];

  dontConfigure = true;
  dontUnpack = true;

  installPhase = ''
    runHook preInstall

    tmp="$(mktemp -d)"
    trap 'rm -rf "$tmp"' EXIT
    cd "$tmp"

    mkdir -p classes
    find "${finalAttrs.src}/src/main/java" -name '*.java' | sort > sources.txt
    ${jdk25}/bin/javac --release 8 -d classes @sources.txt

    while IFS= read -r path; do
      rel_path="$(realpath --relative-to="${finalAttrs.src}/src/main/resources" "$path")"
      install -Dm644 "$path" "classes/$rel_path"
    done < <(find "${finalAttrs.src}/src/main/resources" -type f | sort)

    (
      cd classes
      ${jdk25}/bin/jar cf "$tmp/commons-io-${finalAttrs.version}.jar" .
    )

    mkdir -p "$out"
    install -Dm644 "$tmp/commons-io-${finalAttrs.version}.jar" "$out/commons-io-${finalAttrs.version}.jar"
    install -Dm644 "${finalAttrs.src}/pom.xml" "$out/commons-io-${finalAttrs.version}.pom"

    runHook postInstall
  '';

  meta = with lib; {
    description = "Apache Commons IO library";
    homepage = "https://commons.apache.org/proper/commons-io/";
    license = licenses.asl20;
    platforms = platforms.unix;
  };
})
