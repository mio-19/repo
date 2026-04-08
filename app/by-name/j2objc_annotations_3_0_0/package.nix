{
  fetchurl,
  jdk21,
  lib,
  stdenv,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "j2objc-annotations";
  version = "3.0.0";

  src = fetchurl {
    url = "https://repo.maven.apache.org/maven2/com/google/j2objc/j2objc-annotations/${finalAttrs.version}/j2objc-annotations-${finalAttrs.version}-sources.jar";
    hash = "sha256-vWABmgQjw6Al72qyT+B2H19F/7SKjMp0oBtnjeEQXTg=";
  };

  pom = fetchurl {
    url = "https://repo.maven.apache.org/maven2/com/google/j2objc/j2objc-annotations/${finalAttrs.version}/j2objc-annotations-${finalAttrs.version}.pom";
    hash = "sha256-I7PQOeForYndEUaY5t1744P0osV3uId9gsc6ZRXnShc=";
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
    (
      cd classes
      ${jdk21}/bin/jar cf "$tmp/j2objc-annotations-${finalAttrs.version}.jar" .
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
