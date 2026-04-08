{
  fetchurl,
  jdk21,
  lib,
  stdenv,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "checker-qual";
  version = "3.43.0";

  src = fetchurl {
    url = "https://repo.maven.apache.org/maven2/org/checkerframework/checker-qual/${finalAttrs.version}/checker-qual-${finalAttrs.version}-sources.jar";
    hash = "sha256-1r3uWJZM0Fqr/KTkSUfTy9raa/YX7WGLYrOw1aId4zk=";
  };

  pom = fetchurl {
    url = "https://repo.maven.apache.org/maven2/org/checkerframework/checker-qual/${finalAttrs.version}/checker-qual-${finalAttrs.version}.pom";
    hash = "sha256-kxO/U7Pv2KrKJm7qi5bjB5drZcCxZRDMbwIxn7rr7UM=";
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
    done < <(find . -type f ! -name '*.java' ! -name '*.class' ! -name 'sources.txt' ! -path './META-INF/maven/*' | sort)

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
