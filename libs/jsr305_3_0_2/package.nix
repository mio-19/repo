{
  fetchurl,
  jdk25_headless,
  lib,
  stdenv,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "jsr305";
  version = "3.0.2";

  src = fetchurl {
    url = "https://repo.maven.apache.org/maven2/com/google/code/findbugs/jsr305/${finalAttrs.version}/jsr305-${finalAttrs.version}-sources.jar";
    hash = "sha256-HJ6F4nLQcIxqWR3HSCjHFgMFO0jMda6DzOVpEqKqBjs=";
  };

  pom = fetchurl {
    url = "https://repo.maven.apache.org/maven2/com/google/code/findbugs/jsr305/${finalAttrs.version}/jsr305-${finalAttrs.version}.pom";
    hash = "sha256-GYidvfGyVLJgGl7mRbgUepdGRIgil2hMeYr+XWPXjf4=";
  };

  nativeBuildInputs = [ jdk25_headless ];

  dontConfigure = true;
  dontUnpack = true;

  installPhase = ''
    runHook preInstall

    tmp="$(mktemp -d)"

    cd "$tmp"
    jar xf "$src"

    mkdir -p classes
    find . -name '*.java' > sources.txt
    javac --release 8 -d classes @sources.txt

    while IFS= read -r path; do
      install -Dm644 "$path" "classes/$path"
    done < <(find . -type f ! -name '*.java' ! -name '*.class' ! -name 'sources.txt' ! -path './META-INF/maven/*' | sort)

    (
      cd classes
      jar cf "$tmp/jsr305-${finalAttrs.version}.jar" .
    )

    mkdir -p "$out"
    install -Dm644 "$tmp/jsr305-${finalAttrs.version}.jar" "$out/jsr305-${finalAttrs.version}.jar"
    install -Dm644 "$pom" "$out/jsr305-${finalAttrs.version}.pom"

    runHook postInstall
  '';

  meta = with lib; {
    description = "JSR-305 annotations";
    homepage = "https://github.com/findbugsproject/findbugs";
    license = licenses.asl20;
    platforms = platforms.unix;
  };
})
