{
  fetchurl,
  jdk25_headless,
  lib,
  stdenv,
}:

# Common builder for BouncyCastle provider (bcprov-jdk18on).
# bcprov is a self-contained pure-Java library; it ships resource files
# (service descriptors, property files) alongside its Java sources, so we copy
# those into the class output before packaging the jar.
{
  version,
  srcHash,
  pomHash,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "bcprov-jdk18on";
  inherit version;

  src = fetchurl {
    url = "https://repo.maven.apache.org/maven2/org/bouncycastle/bcprov-jdk18on/${finalAttrs.version}/bcprov-jdk18on-${finalAttrs.version}-sources.jar";
    hash = srcHash;
  };

  pom = fetchurl {
    url = "https://repo.maven.apache.org/maven2/org/bouncycastle/bcprov-jdk18on/${finalAttrs.version}/bcprov-jdk18on-${finalAttrs.version}.pom";
    hash = pomHash;
  };

  nativeBuildInputs = [ jdk25_headless ];

  dontConfigure = true;
  dontUnpack = true;

  installPhase = ''
    runHook preInstall

    tmp="$(mktemp -d)"

    cd "$tmp"
    jar xf "$src"

    # Compile main sources (skip module-info.java which requires --release 9+)
    mkdir -p classes
    find org -name '*.java' ! -name 'module-info.java' | sort > sources.txt
    javac --release 8 -d classes @sources.txt

    # Copy non-Java resources (property files, service descriptors, …)
    while IFS= read -r path; do
      rel_path="$(realpath --relative-to="$tmp" "$path")"
      install -Dm644 "$path" "classes/$rel_path"
    done < <(find org META-INF -type f ! -name '*.java' 2>/dev/null | sort)

    (
      cd classes
      jar cf "$tmp/bcprov-jdk18on-${finalAttrs.version}.jar" .
    )

    mkdir -p "$out"
    install -Dm644 "$tmp/bcprov-jdk18on-${finalAttrs.version}.jar" "$out/bcprov-jdk18on-${finalAttrs.version}.jar"
    install -Dm644 "$pom" "$out/bcprov-jdk18on-${finalAttrs.version}.pom"

    runHook postInstall
  '';

  meta = with lib; {
    description = "BouncyCastle Java cryptography provider";
    homepage = "https://www.bouncycastle.org/";
    license = licenses.mit;
    platforms = platforms.unix;
  };
})
