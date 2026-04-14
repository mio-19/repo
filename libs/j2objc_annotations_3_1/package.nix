{
  fetchFromGitHub,
  fetchurl,
  jdk25_headless,
  lib,
  stdenv,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "j2objc-annotations";
  version = "3.1";

  src = fetchFromGitHub {
    owner = "google";
    repo = "j2objc";
    tag = finalAttrs.version;
    hash = "sha256-hnUlJ81AuXBKb5YjNdW1pM54JcrUnnQa4Eqfwt/2lyU=";
  };

  pom = fetchurl {
    url = "https://repo.maven.apache.org/maven2/com/google/j2objc/j2objc-annotations/${finalAttrs.version}/j2objc-annotations-${finalAttrs.version}.pom";
    hash = "sha256-FFcIOFAANPwbR8ggXOHJ1rJVwczdLRr9zcv3XomySjM=";
  };

  nativeBuildInputs = [ jdk25_headless ];

  dontConfigure = true;
  dontUnpack = true;

  installPhase = ''
    runHook preInstall

    tmp="$(mktemp -d)"

    cd "$tmp"
    mkdir -p classes
    find "${finalAttrs.src}/annotations/src/main/java" -name '*.java' ! -name 'module-info.java' | sort > sources.txt
    javac --release 8 -d classes @sources.txt
    (
      cd classes
      jar cf "$tmp/j2objc-annotations-${finalAttrs.version}.jar" .
    )

    mkdir -p "$out"
    install -Dm644 "$tmp/j2objc-annotations-${finalAttrs.version}.jar" "$out/j2objc-annotations-${finalAttrs.version}.jar"
    install -Dm644 "$pom" "$out/j2objc-annotations-${finalAttrs.version}.pom"

    runHook postInstall
  '';

  meta = with lib; {
    description = "Annotations that provide additional information to the J2ObjC translator";
    homepage = "https://github.com/google/j2objc/";
    license = licenses.asl20;
    platforms = platforms.unix;
  };
})
