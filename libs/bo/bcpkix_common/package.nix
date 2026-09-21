{
  fetchurl,
  jdk25_headless,
  lib,
  stdenv,
}:

# Common builder for BouncyCastle PKIX/CMS/TLS support (bcpkix-jdk18on).
# bcpkix depends on bcprov and bcutil; the caller supplies matching derivations.
{
  version,
  srcHash,
  pomHash,
  bcprov,
  bcutil,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "bcpkix-jdk18on";
  inherit version;

  src = fetchurl {
    url = "https://repo.maven.apache.org/maven2/org/bouncycastle/bcpkix-jdk18on/${finalAttrs.version}/bcpkix-jdk18on-${finalAttrs.version}-sources.jar";
    hash = srcHash;
  };

  pom = fetchurl {
    url = "https://repo.maven.apache.org/maven2/org/bouncycastle/bcpkix-jdk18on/${finalAttrs.version}/bcpkix-jdk18on-${finalAttrs.version}.pom";
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
      -cp "${bcprov}/bcprov-jdk18on-${bcprov.version}.jar:${bcutil}/bcutil-jdk18on-${bcutil.version}.jar" \
      -d classes \
      @sources.txt

    while IFS= read -r path; do
      rel_path="$(realpath --relative-to="$tmp" "$path")"
      install -Dm644 "$path" "classes/$rel_path"
    done < <(find org META-INF -type f ! -name '*.java' 2>/dev/null | sort)

    (
      cd classes
      jar cf "$tmp/bcpkix-jdk18on-${finalAttrs.version}.jar" .
    )

    mkdir -p "$out"
    install -Dm644 "$tmp/bcpkix-jdk18on-${finalAttrs.version}.jar" "$out/bcpkix-jdk18on-${finalAttrs.version}.jar"
    install -Dm644 "$pom" "$out/bcpkix-jdk18on-${finalAttrs.version}.pom"

    runHook postInstall
  '';

  meta = with lib; {
    description = "BouncyCastle PKIX, CMS, EAC, TSP, PKCS, OCSP, CMP, and CRMF APIs for Java";
    homepage = "https://www.bouncycastle.org/";
    license = licenses.mit;
    platforms = platforms.unix;
  };
})
