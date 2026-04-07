{
  fetchurl,
  jdk21,
  lib,
  stdenv,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "error-prone-annotations";
  version = "2.28.0";

  src = fetchurl {
    url = "https://repo.maven.apache.org/maven2/com/google/errorprone/error_prone_annotations/${finalAttrs.version}/error_prone_annotations-${finalAttrs.version}-sources.jar";
    hash = "sha256-KTbpsxXXkNimNk8FdLzsnIsteGiLMX4XZcShb574BjI=";
  };

  pom = fetchurl {
    url = "https://repo.maven.apache.org/maven2/com/google/errorprone/error_prone_annotations/${finalAttrs.version}/error_prone_annotations-${finalAttrs.version}.pom";
    hash = "sha256-DOkJ8TpWgUhHbl7iAPOA+Yx1ugiXGq8V2ylet3WY7zo=";
  };

  parentPom = fetchurl {
    url = "https://repo.maven.apache.org/maven2/com/google/errorprone/error_prone_parent/${finalAttrs.version}/error_prone_parent-${finalAttrs.version}.pom";
    hash = "sha256-rM79u1QWzvX80t3DfbTx/LNKIZPMGlXf5ZcKExs+doM=";
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
    find . -name '*.java' ! -name 'module-info.java' | sort > sources.txt
    ${jdk21}/bin/javac --release 8 -d classes @sources.txt
    if [ -f module-info.java ]; then
      ${jdk21}/bin/javac --release 9 -cp classes -d classes module-info.java
    fi
    (
      cd classes
      ${jdk21}/bin/jar cf "$tmp/error_prone_annotations-${finalAttrs.version}.jar" .
    )

    mkdir -p "$out"
    install -Dm644 "$tmp/error_prone_annotations-${finalAttrs.version}.jar" "$out/error_prone_annotations-${finalAttrs.version}.jar"
    install -Dm644 "$pom" "$out/error_prone_annotations-${finalAttrs.version}.pom"
    install -Dm644 "$parentPom" "$out/error_prone_parent-${finalAttrs.version}.pom"

    runHook postInstall
  '';

  meta = with lib; {
    description = "Annotations for the Error Prone compiler plugin";
    homepage = "https://github.com/google/error-prone";
    license = licenses.asl20;
    platforms = platforms.unix;
  };
})
