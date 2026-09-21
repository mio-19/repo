{
  fetchFromGitHub,
  fetchurl,
  jdk25_headless,
  lib,
  stdenv,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "jakarta.inject-api";
  version = "2.0.1";

  src = fetchFromGitHub {
    owner = "jakartaee";
    repo = "inject";
    tag = finalAttrs.version;
    hash = "sha256-SsPR8C1olO+p+pjrvxUcDzPY+Pjdu5POJyxhWvoJMR4=";
  };

  pom = fetchurl {
    url = "https://repo.maven.apache.org/maven2/jakarta/inject/jakarta.inject-api/${finalAttrs.version}/jakarta.inject-api-${finalAttrs.version}.pom";
    hash = "sha256-5/1yMuljB6V1sklMk2fWjPQ+yYJEqs48zCPhdz/6b9o=";
  };

  nativeBuildInputs = [ jdk25_headless ];

  dontConfigure = true;
  dontUnpack = true;

  installPhase = ''
    runHook preInstall

    tmp="$(mktemp -d)"

    cd "$tmp"

    mkdir -p classes
    find "${finalAttrs.src}/src/main/java" -name '*.java' ! -name 'module-info.java' | sort > sources.txt
    javac --release 8 -d classes @sources.txt
    if [ -f "${finalAttrs.src}/src/main/java/module-info.java" ]; then
      javac --release 9 -cp classes -d classes "${finalAttrs.src}/src/main/java/module-info.java"
    fi

    (
      cd classes
      jar cf "$tmp/jakarta.inject-api-${finalAttrs.version}.jar" .
    )

    mkdir -p "$out"
    install -Dm644 "$tmp/jakarta.inject-api-${finalAttrs.version}.jar" "$out/jakarta.inject-api-${finalAttrs.version}.jar"
    install -Dm644 "$pom" "$out/jakarta.inject-api-${finalAttrs.version}.pom"

    runHook postInstall
  '';

  meta = with lib; {
    description = "Jakarta Dependency Injection";
    homepage = "https://github.com/jakartaee/inject";
    license = licenses.asl20;
    platforms = platforms.unix;
  };
})
