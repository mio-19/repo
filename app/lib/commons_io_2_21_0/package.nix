{
  fetchFromGitHub,
  jdk25_headless,
  lib,
  stdenv,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "commons-io";
  version = "2.21.0";

  src = fetchFromGitHub {
    owner = "apache";
    repo = "commons-io";
    tag = "rel/commons-io-${finalAttrs.version}";
    hash = "sha256-puIa45AX9bioN6fXKhzVGNaJ1sPttNfnv2QMh3hEdnM=";
  };

  nativeBuildInputs = [ jdk25_headless ];

  dontConfigure = true;
  dontUnpack = true;

  installPhase = ''
    runHook preInstall

    tmp="$(mktemp -d)"
    trap 'rm -rf "$tmp"' EXIT
    cd "$tmp"

    mkdir -p classes
    find "${finalAttrs.src}/src/main/java" -name '*.java' ! -name 'module-info.java' | sort > sources.txt
    javac --release 8 -d classes @sources.txt
    if [ -f "${finalAttrs.src}/src/main/java/module-info.java" ]; then
      javac --release 9 -cp classes -d classes "${finalAttrs.src}/src/main/java/module-info.java"
    fi

    while IFS= read -r path; do
      rel_path="$(realpath --relative-to="${finalAttrs.src}/src/main/resources" "$path")"
      install -Dm644 "$path" "classes/$rel_path"
    done < <(find "${finalAttrs.src}/src/main/resources" -type f | sort)

    (
      cd classes
      jar cf "$tmp/commons-io-${finalAttrs.version}.jar" .
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
