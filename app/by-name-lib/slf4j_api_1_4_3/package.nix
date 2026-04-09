{
  fetchFromGitHub,
  jdk21,
  lib,
  stdenv,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "slf4j-api";
  version = "1.4.3";

  src = fetchFromGitHub {
    owner = "qos-ch";
    repo = "slf4j";
    tag = "SLF4J_1.4.3";
    hash = "sha256-KYcHj4s0Es1hXZrGoV0YG3DQp6H0gaHOS8W0gDWxwJw=";
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
    find "${finalAttrs.src}/slf4j-api/src/main/java" -name '*.java' | sort > sources.txt
    ${jdk21}/bin/javac --release 8 -d classes @sources.txt
    rm -rf classes/org/slf4j/impl

    resource_root="${finalAttrs.src}/slf4j-api/src/main/resources"
    if [ -d "$resource_root" ]; then
      find "$resource_root" -type f | sort | while IFS= read -r path; do
        rel_path="$(realpath --relative-to="$resource_root" "$path")"
        install -Dm644 "$path" "classes/$rel_path"
      done
    fi

    (
      cd classes
      ${jdk21}/bin/jar cf "$tmp/slf4j-api-${finalAttrs.version}.jar" .
    )

    mkdir -p "$out"
    install -Dm644 "$tmp/slf4j-api-${finalAttrs.version}.jar" "$out/slf4j-api-${finalAttrs.version}.jar"
    install -Dm644 "${finalAttrs.src}/slf4j-api/pom.xml" "$out/slf4j-api-${finalAttrs.version}.pom"

    runHook postInstall
  '';

  meta = with lib; {
    description = "Simple Logging Facade for Java API";
    homepage = "https://www.slf4j.org/";
    license = licenses.mit;
    platforms = platforms.unix;
  };
})
