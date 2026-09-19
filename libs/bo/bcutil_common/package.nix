{
  fetchurl,
  jdk25_headless,
  lib,
  stdenv,
}:

# Common builder for BouncyCastle utility library (bcutil-jdk18on).
# bcutil depends on bcprov; the caller must supply the matching bcprov derivation.
{
  version,
  srcHash,
  pomHash,
  bcprov,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "bcutil-jdk18on";
  inherit version;

  src = fetchurl {
    url = "https://repo.maven.apache.org/maven2/org/bouncycastle/bcutil-jdk18on/${finalAttrs.version}/bcutil-jdk18on-${finalAttrs.version}-sources.jar";
    hash = srcHash;
  };

  pom = fetchurl {
    url = "https://repo.maven.apache.org/maven2/org/bouncycastle/bcutil-jdk18on/${finalAttrs.version}/bcutil-jdk18on-${finalAttrs.version}.pom";
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

    mkdir -p classes
    find org -name '*.java' ! -name 'module-info.java' | sort > sources.txt
    javac --release 8 \
      -cp "${bcprov}/bcprov-jdk18on-${bcprov.version}.jar" \
      -d classes \
      @sources.txt

    while IFS= read -r path; do
      rel_path="$(realpath --relative-to="$tmp" "$path")"
      install -Dm644 "$path" "classes/$rel_path"
    done < <(find org META-INF -type f ! -name '*.java' 2>/dev/null | sort)

    (
      cd classes
      jar cf "$tmp/bcutil-jdk18on-${finalAttrs.version}.jar" .
    )

    mkdir -p "$out"
    install -Dm644 "$tmp/bcutil-jdk18on-${finalAttrs.version}.jar" "$out/bcutil-jdk18on-${finalAttrs.version}.jar"
    install -Dm644 "$pom" "$out/bcutil-jdk18on-${finalAttrs.version}.pom"

    runHook postInstall
  '';

  meta = with lib; {
    description = "BouncyCastle utility classes for Java";
    homepage = "https://www.bouncycastle.org/";
    license = licenses.mit;
    platforms = platforms.unix;
  };
})
