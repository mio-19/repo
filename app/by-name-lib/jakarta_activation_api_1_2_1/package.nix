{
  fetchFromGitHub,
  fetchurl,
  jdk21,
  lib,
  stdenv,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "jakarta.activation-api";
  version = "1.2.1";

  src = fetchFromGitHub {
    owner = "eclipse-ee4j";
    repo = "jaf";
    tag = finalAttrs.version;
    hash = "sha256-xhDyMOf+/KFQQo7CbwtrnJJuXoyjvtluTcKAYp42q/Y=";
  };

  pomFile = fetchurl {
    url = "https://repo.maven.apache.org/maven2/jakarta/activation/jakarta.activation-api/1.2.1/jakarta.activation-api-1.2.1.pom";
    hash = "sha256-QlhcsH3afyOqBOteCUAGGUSiRqZ609FpQvvlaf8DzTE=";
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
    find "${finalAttrs.src}/activation/src/main/java" -name '*.java' | sort > sources.txt
    javac --release 8 -encoding UTF-8 -d classes @sources.txt

    resource_root="${finalAttrs.src}/activation/src/main/resources"
    find "$resource_root" -type f | sort | while IFS= read -r path; do
      rel_path="$(realpath --relative-to="$resource_root" "$path")"
      install -Dm644 "$path" "classes/$rel_path"
    done

    (
      cd classes
      jar cf "$tmp/jakarta.activation-api-${finalAttrs.version}.jar" .
    )

    mkdir -p "$out"
    install -Dm644 "$tmp/jakarta.activation-api-${finalAttrs.version}.jar" "$out/jakarta.activation-api-${finalAttrs.version}.jar"
    install -Dm644 "${finalAttrs.pomFile}" "$out/jakarta.activation-api-${finalAttrs.version}.pom"

    runHook postInstall
  '';

  meta = with lib; {
    description = "Jakarta Activation API";
    homepage = "https://github.com/eclipse-ee4j/jaf";
    license = [
      licenses.bsd3
      licenses.epl10
    ];
    platforms = platforms.unix;
  };
})
