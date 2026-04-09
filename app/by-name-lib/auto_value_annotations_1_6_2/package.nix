{
  fetchFromGitHub,
  jdk25,
  lib,
  stdenv,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "auto-value-annotations";
  version = "1.6.2";

  src = fetchFromGitHub {
    owner = "google";
    repo = "auto";
    tag = "auto-value-${finalAttrs.version}";
    hash = "sha256-D8ZppkX82bKxZNIxGboSW0Q1uDJKe1Cu7hOW2E6xc1s=";
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
    find "${finalAttrs.src}/value/src/main/java/com/google/auto/value" -maxdepth 1 -name '*.java' | sort > sources.txt
    find "${finalAttrs.src}/value/src/main/java/com/google/auto/value/extension/memoized" -maxdepth 1 -name '*.java' | sort >> sources.txt
    ${jdk25}/bin/javac --release 8 -d classes @sources.txt

    (
      cd classes
      ${jdk25}/bin/jar cf "$tmp/auto-value-annotations-${finalAttrs.version}.jar" .
    )

    mkdir -p "$out"
    install -Dm644 "$tmp/auto-value-annotations-${finalAttrs.version}.jar" "$out/auto-value-annotations-${finalAttrs.version}.jar"
    install -Dm644 "${finalAttrs.src}/value/annotations/pom.xml" "$out/auto-value-annotations-${finalAttrs.version}.pom"
    install -Dm644 "${finalAttrs.src}/value/pom.xml" "$out/auto-value-parent-${finalAttrs.version}.pom"

    runHook postInstall
  '';

  meta = with lib; {
    description = "Annotations for AutoValue";
    homepage = "https://github.com/google/auto";
    license = licenses.asl20;
    platforms = platforms.unix;
  };
})
