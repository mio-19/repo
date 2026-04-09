{
  fetchFromGitHub,
  jdk25,
  lib,
  stdenv,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "javax.inject";
  version = "1";

  src = fetchFromGitHub {
    owner = "javax-inject";
    repo = "javax-inject";
    tag = finalAttrs.version;
    hash = "sha256-/cgR2LZVRO5cFf5Os4SU1LDYR+IzMmaNizLMPS2gV+c=";
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
    find "${finalAttrs.src}/src" -name '*.java' | sort > sources.txt
    ${jdk25}/bin/javac --release 8 -d classes @sources.txt

    (
      cd classes
      ${jdk25}/bin/jar cf "$tmp/javax.inject-${finalAttrs.version}.jar" .
    )

    mkdir -p "$out"
    install -Dm644 "$tmp/javax.inject-${finalAttrs.version}.jar" "$out/javax.inject-${finalAttrs.version}.jar"
    install -Dm644 "${finalAttrs.src}/pom.xml" "$out/javax.inject-${finalAttrs.version}.pom"

    runHook postInstall
  '';

  meta = with lib; {
    description = "Dependency injection annotations for Java";
    homepage = "https://github.com/javax-inject/javax-inject";
    license = licenses.asl20;
    platforms = platforms.unix;
  };
})
