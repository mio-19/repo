{
  fetchFromGitHub,
  jdk21_headless,
  lib,
  stdenv,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "error-prone-annotations";
  version = "2.5.1";

  src = fetchFromGitHub {
    owner = "google";
    repo = "error-prone";
    tag = "v${finalAttrs.version}";
    hash = "sha256-Y8agU4i7rFvz+EWf/isa2f3uuY4QzqUO5Gw591J0h3Q=";
  };

  nativeBuildInputs = [ jdk21_headless ];

  dontConfigure = true;
  dontUnpack = true;

  installPhase = ''
    runHook preInstall

    tmp="$(mktemp -d)"

    cd "$tmp"
    mkdir -p classes
    find "${finalAttrs.src}/annotations/src/main/java" -name '*.java' ! -name 'module-info.java' | sort > sources.txt
    javac --release 8 -d classes @sources.txt
    if [ -f "${finalAttrs.src}/annotations/src/main/java/module-info.java" ]; then
      javac --release 9 -cp classes -d classes "${finalAttrs.src}/annotations/src/main/java/module-info.java"
    fi
    (
      cd classes
      jar cf "$tmp/error_prone_annotations-${finalAttrs.version}.jar" .
    )

    mkdir -p "$out"
    install -Dm644 "$tmp/error_prone_annotations-${finalAttrs.version}.jar" "$out/error_prone_annotations-${finalAttrs.version}.jar"
    install -Dm644 "${finalAttrs.src}/annotations/pom.xml" "$out/error_prone_annotations-${finalAttrs.version}.pom"
    install -Dm644 "${finalAttrs.src}/pom.xml" "$out/error_prone_parent-${finalAttrs.version}.pom"

    runHook postInstall
  '';

  meta = with lib; {
    description = "Annotations for the Error Prone compiler plugin";
    homepage = "https://github.com/google/error-prone";
    license = licenses.asl20;
    platforms = platforms.unix;
  };
})
