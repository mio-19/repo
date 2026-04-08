{
  fetchFromGitHub,
  jdk21,
  lib,
  stdenv,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "j2objc-annotations";
  version = "2.8";

  src = fetchFromGitHub {
    owner = "google";
    repo = "j2objc";
    tag = finalAttrs.version;
    hash = "sha256-7cE5nGXe48j3ArdHi+3swmLHHOi8m6YWBUw6s1ikm4Q=";
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
    find "${finalAttrs.src}/annotations/src/main/java" -name '*.java' ! -name 'module-info.java' | sort > sources.txt
    ${jdk21}/bin/javac --release 8 -d classes @sources.txt
    (
      cd classes
      ${jdk21}/bin/jar cf "$tmp/j2objc-annotations-${finalAttrs.version}.jar" .
    )

    mkdir -p "$out"
    install -Dm644 "$tmp/j2objc-annotations-${finalAttrs.version}.jar" "$out/j2objc-annotations-${finalAttrs.version}.jar"
    install -Dm644 "${finalAttrs.src}/annotations/pom.xml" "$out/j2objc-annotations-${finalAttrs.version}.pom"

    runHook postInstall
  '';

  meta = with lib; {
    description = "Annotations that provide additional information to the J2ObjC translator";
    homepage = "https://github.com/google/j2objc/";
    license = licenses.asl20;
    platforms = platforms.unix;
  };
})
