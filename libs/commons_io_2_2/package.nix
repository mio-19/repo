{
  fetchFromGitHub,
  jdk21_headless,
  lib,
  stdenv,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "commons-io";
  version = "2.2";

  src = fetchFromGitHub {
    owner = "apache";
    repo = "commons-io";
    tag = finalAttrs.version;
    hash = "sha256-iU6VhKW6m1ltqd4lfwnd0qIgYJVAhQvaLS6dfmW6CZY=";
  };

  nativeBuildInputs = [ jdk21_headless ];

  dontConfigure = true;
  dontUnpack = true;

  installPhase = ''
    runHook preInstall

    tmp="$(mktemp -d)"
    
    cd "$tmp"

    mkdir -p classes
    find "${finalAttrs.src}/src/main/java" -name '*.java' | sort > sources.txt
    javac --release 8 -d classes @sources.txt

    resource_root="${finalAttrs.src}/src/main/resources"
    if [ -d "$resource_root" ]; then
      find "$resource_root" -type f | sort | while IFS= read -r path; do
        rel_path="$(realpath --relative-to="$resource_root" "$path")"
        install -Dm644 "$path" "classes/$rel_path"
      done
    fi

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
