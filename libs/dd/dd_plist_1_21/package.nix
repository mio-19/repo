{
  fetchurl,
  jdk21_headless,
  lib,
  stdenv,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "dd-plist";
  version = "1.21";

  src = fetchurl {
    url = "https://repo.maven.apache.org/maven2/com/googlecode/plist/dd-plist/${finalAttrs.version}/dd-plist-${finalAttrs.version}-sources.jar";
    hash = "sha256-fhWOM9i3FrRqqtPItRUrh8cY55tBikWZaazZ9czENzY=";
  };

  pom = fetchurl {
    url = "https://repo.maven.apache.org/maven2/com/googlecode/plist/dd-plist/${finalAttrs.version}/dd-plist-${finalAttrs.version}.pom";
    hash = "sha256-dRv61EYSO7TWG6sp+LS/D3NUNqqXVxkLw9DwBFsJ5RQ=";
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
    find src/main/java -name '*.java' > sources.txt
    javac --release 8 -d classes @sources.txt

    (
      cd classes
      jar cf "$tmp/dd-plist-${finalAttrs.version}.jar" .
    )

    mkdir -p "$out"
    install -Dm644 "$tmp/dd-plist-${finalAttrs.version}.jar" "$out/dd-plist-${finalAttrs.version}.jar"
    install -Dm644 "$pom" "$out/dd-plist-${finalAttrs.version}.pom"

    runHook postInstall
  '';

  meta = with lib; {
    description = "Java library for handling Apple property list files";
    homepage = "https://github.com/3breadt/dd-plist";
    license = licenses.mit;
    platforms = platforms.unix;
  };
})
