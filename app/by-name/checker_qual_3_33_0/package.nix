{
  fetchurl,
  jdk21,
  lib,
  stdenv,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "checker-qual";
  version = "3.33.0";

  src = fetchurl {
    url = "https://repo.maven.apache.org/maven2/org/checkerframework/checker-qual/${finalAttrs.version}/checker-qual-${finalAttrs.version}-sources.jar";
    hash = "sha256-RD+mFRmCu0xs5i4pOPU2YAhbE6fc61FyAnd7h9Deosc=";
  };

  pom = fetchurl {
    url = "https://repo.maven.apache.org/maven2/org/checkerframework/checker-qual/${finalAttrs.version}/checker-qual-${finalAttrs.version}.pom";
    hash = "sha256-9VqSICenj92LPqFaDYv+P+xqXOrDDIaqivpKW5sN9gM=";
  };

  nativeBuildInputs = [ jdk21 ];

  dontConfigure = true;
  dontUnpack = true;

  installPhase = ''
    runHook preInstall

    tmp="$(mktemp -d)"
    trap 'rm -rf "$tmp"' EXIT
    cd "$tmp"
    ${jdk21}/bin/jar xf "$src"

    mkdir -p classes
    find . -name '*.java' | sort > sources.txt
    ${jdk21}/bin/javac --release 8 -d classes @sources.txt

    while IFS= read -r path; do
      install -Dm644 "$path" "classes/$path"
    done < <(find . -type f ! -name '*.java' ! -name 'sources.txt' ! -path './META-INF/maven/*' | sort)

    (
      cd classes
      ${jdk21}/bin/jar cf "$tmp/checker-qual-${finalAttrs.version}.jar" .
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
