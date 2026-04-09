{
  fetchFromGitHub,
  fetchurl,
  jdk25,
  lib,
  stdenv,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "checker-qual";
  version = "3.33.0";

  src = fetchFromGitHub {
    owner = "typetools";
    repo = "checker-framework";
    tag = "checker-framework-${finalAttrs.version}";
    hash = "sha256-4Ud7UL5Zo2lsXT8ke8VEKswupIcrXGFcd5I+LI1EfFM=";
  };

  pom = fetchurl {
    url = "https://repo.maven.apache.org/maven2/org/checkerframework/checker-qual/${finalAttrs.version}/checker-qual-${finalAttrs.version}.pom";
    hash = "sha256-9VqSICenj92LPqFaDYv+P+xqXOrDDIaqivpKW5sN9gM=";
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
    find "${finalAttrs.src}/checker-qual/src/main/java" -name '*.java' ! -name 'module-info.java' | sort > sources.txt
    ${jdk25}/bin/javac --release 8 -d classes @sources.txt
    if [ -f "${finalAttrs.src}/checker-qual/src/main/java/module-info.java" ]; then
      ${jdk25}/bin/javac --release 9 -cp classes -d classes "${finalAttrs.src}/checker-qual/src/main/java/module-info.java"
    fi

    while IFS= read -r path; do
      rel_path="$(realpath --relative-to="${finalAttrs.src}/checker-qual/src/main/java" "$path")"
      install -Dm644 "$path" "classes/$rel_path"
    done < <(find "${finalAttrs.src}/checker-qual/src/main/java" -type f ! -name '*.java' | sort)

    (
      cd classes
      ${jdk25}/bin/jar cf "$tmp/checker-qual-${finalAttrs.version}.jar" .
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
