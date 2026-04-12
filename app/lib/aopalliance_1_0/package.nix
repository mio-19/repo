{
  fetchurl,
  jdk21_headless,
  lib,
  stdenv,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "aopalliance";
  version = "1.0";

  src = fetchurl {
    url = "https://repo.maven.apache.org/maven2/aopalliance/aopalliance/${finalAttrs.version}/aopalliance-${finalAttrs.version}-sources.jar";
    hash = "sha256-5u+R1DmtqQRfQZx3VD6+BBbDzfxbBjRINDQXo+SnISM=";
  };

  pom = fetchurl {
    url = "https://repo.maven.apache.org/maven2/aopalliance/aopalliance/${finalAttrs.version}/aopalliance-${finalAttrs.version}.pom";
    hash = "sha256-JugjMBV9a4RLZ6gGSUXiBlgedyl3GD4+Mf7GBYqppZs=";
  };

  nativeBuildInputs = [ jdk21_headless ];

  dontConfigure = true;
  dontUnpack = true;

  installPhase = ''
    runHook preInstall

    tmp="$(mktemp -d)"
    trap 'rm -rf "$tmp"' EXIT
    cd "$tmp"
    jar xf "$src"

    mkdir -p classes
    find org -name '*.java' | sort > sources.txt
    javac --release 8 -d classes @sources.txt

    (
      cd classes
      jar cf "$tmp/aopalliance-${finalAttrs.version}.jar" .
    )

    mkdir -p "$out"
    install -Dm644 "$tmp/aopalliance-${finalAttrs.version}.jar" "$out/aopalliance-${finalAttrs.version}.jar"
    install -Dm644 "$pom" "$out/aopalliance-${finalAttrs.version}.pom"

    runHook postInstall
  '';

  meta = with lib; {
    description = "AOP Alliance interfaces";
    homepage = "http://aopalliance.sourceforge.net/";
    license = licenses.publicDomain;
    platforms = platforms.unix;
  };
})
