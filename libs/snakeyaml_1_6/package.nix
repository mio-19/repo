{
  fetchurl,
  jdk21_headless,
  lib,
  stdenv,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "snakeyaml";
  version = "1.6";

  src = fetchurl {
    url = "https://repo.maven.apache.org/maven2/org/yaml/snakeyaml/${finalAttrs.version}/snakeyaml-${finalAttrs.version}-sources.jar";
    hash = "sha256-qAJkWhSyUD/Z57SMDc+HDIpFN0I+oZQFo3Ln87xauHo=";
  };

  pom = fetchurl {
    url = "https://repo.maven.apache.org/maven2/org/yaml/snakeyaml/${finalAttrs.version}/snakeyaml-${finalAttrs.version}.pom";
    hash = "sha256-E2ABG4BVusQPcZo87LBjDeoU+e91K+Qk+1obA/UVjq0=";
  };

  nativeBuildInputs = [ jdk21_headless ];

  dontConfigure = true;
  dontUnpack = true;

  installPhase = ''
    runHook preInstall

    tmp="$(mktemp -d)"
    
    cd "$tmp"
    jar xf "$src"

    mkdir -p classes
    find org -name '*.java' | sort > sources.txt
    javac --release 8 -d classes @sources.txt

    (
      cd classes
      jar cf "$tmp/snakeyaml-${finalAttrs.version}.jar" .
    )

    mkdir -p "$out"
    install -Dm644 "$tmp/snakeyaml-${finalAttrs.version}.jar" "$out/snakeyaml-${finalAttrs.version}.jar"
    install -Dm644 "$pom" "$out/snakeyaml-${finalAttrs.version}.pom"

    runHook postInstall
  '';

  meta = with lib; {
    description = "YAML parser and emitter for Java";
    homepage = "https://bitbucket.org/snakeyaml/snakeyaml";
    license = licenses.asl20;
    platforms = platforms.unix;
  };
})
