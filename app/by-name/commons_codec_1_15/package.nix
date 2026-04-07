{
  fetchurl,
  jdk21,
  lib,
  stdenv,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "commons-codec";
  version = "1.15";

  src = fetchurl {
    url = "https://repo.maven.apache.org/maven2/commons-codec/commons-codec/${finalAttrs.version}/commons-codec-${finalAttrs.version}-sources.jar";
    hash = "sha256-cBmUCyKY0zPtuUbi2z0Q8cqsu9Urtk6Fgyz9ABfgScw=";
  };

  pom = fetchurl {
    url = "https://repo.maven.apache.org/maven2/commons-codec/commons-codec/${finalAttrs.version}/commons-codec-${finalAttrs.version}.pom";
    hash = "sha256-yG7hmKNaNxVIeGD0Gcv2Qufk2ehxR3eUfb5qTjogq1g=";
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
    done < <(find . -type f ! -name '*.java' ! -path './META-INF/maven/*' | sort)

    (
      cd classes
      ${jdk21}/bin/jar cf "$tmp/commons-codec-${finalAttrs.version}.jar" .
    )

    mkdir -p "$out"
    install -Dm644 "$tmp/commons-codec-${finalAttrs.version}.jar" "$out/commons-codec-${finalAttrs.version}.jar"
    install -Dm644 "$pom" "$out/commons-codec-${finalAttrs.version}.pom"

    runHook postInstall
  '';

  meta = with lib; {
    description = "Apache Commons Codec";
    homepage = "https://commons.apache.org/proper/commons-codec/";
    license = licenses.asl20;
    platforms = platforms.unix;
  };
})
