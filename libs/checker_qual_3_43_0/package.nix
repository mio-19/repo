{
  fetchFromGitHub,
  fetchurl,
  jdk25_headless,
  lib,
  stdenv,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "checker-qual";
  version = "3.43.0";

  src = fetchFromGitHub {
    owner = "typetools";
    repo = "checker-framework";
    tag = "checker-framework-${finalAttrs.version}";
    hash = "sha256-xmivQ8QlU2ER2W85d4WGbymnkz59oaJwIVViG3WVDo8=";
  };

  pom = fetchurl {
    url = "https://repo.maven.apache.org/maven2/org/checkerframework/checker-qual/${finalAttrs.version}/checker-qual-${finalAttrs.version}.pom";
    hash = "sha256-kxO/U7Pv2KrKJm7qi5bjB5drZcCxZRDMbwIxn7rr7UM=";
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
    find "${finalAttrs.src}/checker-qual/src/main/java" -name '*.java' ! -name 'module-info.java' | sort > sources.txt
    javac --release 8 -d classes @sources.txt
    if [ -f "${finalAttrs.src}/checker-qual/src/main/java/module-info.java" ]; then
      javac --release 9 -cp classes -d classes "${finalAttrs.src}/checker-qual/src/main/java/module-info.java"
    fi

    while IFS= read -r path; do
      rel_path="$(realpath --relative-to="${finalAttrs.src}/checker-qual/src/main/java" "$path")"
      install -Dm644 "$path" "classes/$rel_path"
    done < <(find "${finalAttrs.src}/checker-qual/src/main/java" -type f ! -name '*.java' | sort)

    (
      cd classes
      jar cf "$tmp/checker-qual-${finalAttrs.version}.jar" .
    )

    mkdir -p "$out"
    install -Dm644 "$tmp/checker-qual-${finalAttrs.version}.jar" "$out/checker-qual-${finalAttrs.version}.jar"
    install -Dm644 "$pom" "$out/checker-qual-${finalAttrs.version}.pom"

    runHook postInstall
  '';

  meta = with lib; {
    description = "Checker Framework annotations";
    homepage = "https://checkerframework.org/";
    license = licenses.gpl2Only;
    platforms = platforms.unix;
  };
})
