{
  fetchFromGitHub,
  fetchurl,
  jdk25_headless,
  lib,
  stdenv,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "jdom2";
  version = "2.0.6";

  src = fetchFromGitHub {
    owner = "hunterhacker";
    repo = "jdom";
    tag = "JDOM-${finalAttrs.version}";
    hash = "sha256-OPaXezfl8r4hRjRWz9LczvjCEcmm5/EZiXw3nfsMe5M=";
  };

  pomFile = fetchurl {
    url = "https://repo.maven.apache.org/maven2/org/jdom/jdom2/2.0.6/jdom2-2.0.6.pom";
    hash = "sha256-R7I6ef4za3QbgkNMbgSdaBZSVuQF51wQkh/XL6imXY0=";
  };

  nativeBuildInputs = [ jdk25_headless ];

  dontConfigure = true;
  dontUnpack = true;

  installPhase = ''
    runHook preInstall

    tmp="$(mktemp -d)"
    trap 'rm -rf "$tmp"' EXIT
    cd "$tmp"

    cp -r "${finalAttrs.src}/core/src/java" src
    chmod -R u+w src
    substituteInPlace src/org/jdom2/JDOMConstants.java \
      --replace-fail 'import org.jdom2.xpath.XPathFactory;' ""

    mkdir -p classes
    find src -name '*.java' \
      ! -path '*/org/jdom2/xpath/*' \
      | sort > sources.txt
    javac --release 8 -encoding UTF-8 -d classes @sources.txt

    (
      cd classes
      jar cf "$tmp/jdom2-${finalAttrs.version}.jar" .
    )

    mkdir -p "$out"
    install -Dm644 "$tmp/jdom2-${finalAttrs.version}.jar" "$out/jdom2-${finalAttrs.version}.jar"
    install -Dm644 "${finalAttrs.pomFile}" "$out/jdom2-${finalAttrs.version}.pom"

    runHook postInstall
  '';

  meta = with lib; {
    description = "Java-based document object model for XML";
    homepage = "https://github.com/hunterhacker/jdom";
    license = licenses.bsdOriginal;
    platforms = platforms.unix;
  };
})
