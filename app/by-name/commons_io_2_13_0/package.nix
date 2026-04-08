{
  fetchurl,
  jdk21,
  lib,
  stdenv,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "commons-io";
  version = "2.13.0";

  src = fetchurl {
    url = "https://repo.maven.apache.org/maven2/commons-io/commons-io/${finalAttrs.version}/commons-io-${finalAttrs.version}-sources.jar";
    hash = "sha256-HHvs4uh6xJsk8J7Dxc61FWDt16JZiJ/O75bdqcBGobM=";
  };

  pom = fetchurl {
    url = "https://repo.maven.apache.org/maven2/commons-io/commons-io/${finalAttrs.version}/commons-io-${finalAttrs.version}.pom";
    hash = "sha256-2z/tZMLhd06/1rGnSQN3MrFJuREd1+a5hfCN2lVHBDk=";
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
      ${jdk21}/bin/jar cf "$tmp/commons-io-${finalAttrs.version}.jar" .
    )

    mkdir -p "$out"
    install -Dm644 "$tmp/commons-io-${finalAttrs.version}.jar" "$out/commons-io-${finalAttrs.version}.jar"
    install -Dm644 "$pom" "$out/commons-io-${finalAttrs.version}.pom"

    runHook postInstall
  '';

  meta = with lib; {
    description = "Apache Commons IO library";
    homepage = "https://commons.apache.org/proper/commons-io/";
    license = licenses.asl20;
    platforms = platforms.unix;
  };
})
