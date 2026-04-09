{
  fetchFromGitHub,
  jdk25,
  lib,
  stdenv,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "failureaccess";
  version = "1.0.2";

  src = fetchFromGitHub {
    owner = "google";
    repo = "guava";
    tag = "failureaccess-v${finalAttrs.version}";
    hash = "sha256-FVmcCSeyy0lZ6K3b9eMTqEna3ZG0g1x8+HTQV7Dy77s=";
  };

  parentSrc = fetchFromGitHub {
    owner = "google";
    repo = "guava";
    tag = "v26.0";
    hash = "sha256-Y7Crkd32PyYCy/GAOJB5KaS/qBsV005paLoWuAB48+M=";
  };

  nativeBuildInputs = [ jdk25 ];

  dontConfigure = true;
  dontUnpack = true;

  installPhase = ''
    runHook preInstall

    tmp="$(mktemp -d)"
    trap 'rm -rf "$tmp"' EXIT
    cd "$tmp"
    mkdir -p classes
    find "${finalAttrs.src}/futures/failureaccess/src" -name '*.java' | sort > sources.txt
    ${jdk25}/bin/javac --release 8 -d classes @sources.txt
    (
      cd classes
      ${jdk25}/bin/jar cf "$tmp/failureaccess-${finalAttrs.version}.jar" .
    )

    mkdir -p "$out"
    install -Dm644 "$tmp/failureaccess-${finalAttrs.version}.jar" "$out/failureaccess-${finalAttrs.version}.jar"
    install -Dm644 "${finalAttrs.src}/futures/failureaccess/pom.xml" "$out/failureaccess-${finalAttrs.version}.pom"
    install -Dm644 "${finalAttrs.parentSrc}/android/pom.xml" "$out/guava-parent-26.0-android.pom"

    runHook postInstall
  '';

  meta = with lib; {
    description = "Guava internal future failure access helper";
    homepage = "https://github.com/google/guava";
    license = licenses.asl20;
    platforms = platforms.unix;
  };
})
