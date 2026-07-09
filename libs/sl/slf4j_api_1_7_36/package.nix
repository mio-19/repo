{
  fetchFromGitHub,
  jdk25_headless,
  lib,
  stdenv,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "slf4j-api";
  version = "1.7.36";

  src = fetchFromGitHub {
    owner = "qos-ch";
    repo = "slf4j";
    tag = "v_${finalAttrs.version}";
    hash = "sha256-A891wuusRHJJJHDTLqKgT6sRUFZQioAk1u1tpnbWbRY=";
  };

  nativeBuildInputs = [ jdk25_headless ];

  dontConfigure = true;
  dontUnpack = true;

  installPhase = ''
    runHook preInstall

    tmp="$(mktemp -d)"

    cd "$tmp"

    mkdir -p classes
    find "${finalAttrs.src}/slf4j-api/src/main/java" -name '*.java' > sources.txt
    javac --release 8 -d classes @sources.txt
    rm -rf classes/org/slf4j/impl

    resource_root="${finalAttrs.src}/slf4j-api/src/main/resources"
    find "$resource_root" -type f | sort | while IFS= read -r path; do
      rel_path="$(realpath --relative-to="$resource_root" "$path")"
      install -Dm644 "$path" "classes/$rel_path"
    done

    (
      cd classes
      jar cf "$tmp/slf4j-api-${finalAttrs.version}.jar" .
    )

    mkdir -p "$out"
    install -Dm644 "$tmp/slf4j-api-${finalAttrs.version}.jar" "$out/slf4j-api-${finalAttrs.version}.jar"
    install -Dm644 "${finalAttrs.src}/slf4j-api/pom.xml" "$out/slf4j-api-${finalAttrs.version}.pom"
    install -Dm644 "${finalAttrs.src}/pom.xml" "$out/slf4j-parent-${finalAttrs.version}.pom"

    runHook postInstall
  '';

  meta = with lib; {
    description = "Simple Logging Facade for Java API";
    homepage = "https://www.slf4j.org/";
    license = licenses.mit;
    platforms = platforms.unix;
  };
})
