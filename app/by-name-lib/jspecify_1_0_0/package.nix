{
  fetchurl,
  jdk21,
  lib,
  stdenv,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "jspecify";
  version = "1.0.0";

  srcJar = fetchurl {
    url = "https://repo.maven.apache.org/maven2/org/jspecify/jspecify/1.0.0/jspecify-1.0.0-sources.jar";
    hash = "sha256-rfCJgZHVWTf7MZK6lxgm9PKUKSxKlgdA88JzEOe3ApY=";
  };

  pomFile = fetchurl {
    url = "https://repo.maven.apache.org/maven2/org/jspecify/jspecify/1.0.0/jspecify-1.0.0.pom";
    hash = "sha256-zauSmjuVIR9D0gkMXi0N/oRllg43i8MrNYQdqzJEM6Y=";
  };

  moduleFile = fetchurl {
    url = "https://repo.maven.apache.org/maven2/org/jspecify/jspecify/1.0.0/jspecify-1.0.0.module";
    hash = "sha256-0wfKd6VOGKwe8artTlu+AUvS9J8p4dL4E+R8J4KDGVs=";
  };

  nativeBuildInputs = [ jdk21 ];

  dontConfigure = true;
  dontUnpack = true;

  installPhase = ''
    runHook preInstall

    tmp="$(mktemp -d)"
    trap 'rm -rf "$tmp"' EXIT
    cd "$tmp"

    ${jdk21}/bin/jar xf "${finalAttrs.srcJar}"
    find org -name '*.java' | sort > sources.txt
    mkdir -p classes
    ${jdk21}/bin/javac --release 9 -encoding UTF-8 -d classes @sources.txt

    (
      cd classes
      ${jdk21}/bin/jar cf "$tmp/jspecify-${finalAttrs.version}.jar" .
    )

    mkdir -p "$out"
    install -Dm644 "$tmp/jspecify-${finalAttrs.version}.jar" "$out/jspecify-${finalAttrs.version}.jar"
    install -Dm644 "${finalAttrs.pomFile}" "$out/jspecify-${finalAttrs.version}.pom"
    install -Dm644 "${finalAttrs.moduleFile}" "$out/jspecify-${finalAttrs.version}.module"

    runHook postInstall
  '';

  meta = with lib; {
    description = "JSpecify nullness annotations";
    homepage = "https://jspecify.dev/";
    license = licenses.asl20;
    platforms = platforms.unix;
  };
})
