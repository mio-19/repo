{
  fetchFromGitHub,
  jdk25_headless,
  lib,
  stdenv,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "failureaccess";
  version = "1.0.1";

  src = fetchFromGitHub {
    owner = "google";
    repo = "guava";
    tag = "failureaccess-v${finalAttrs.version}";
    hash = "sha256-dHdKL4HVBS0dCDNbNPA1SBhB/pfC6yPkAB3FjHM62tk=";
  };

  parentSrc = fetchFromGitHub {
    owner = "google";
    repo = "guava";
    tag = "v26.0";
    hash = "sha256-Y7Crkd32PyYCy/GAOJB5KaS/qBsV005paLoWuAB48+M=";
  };

  nativeBuildInputs = [ jdk25_headless ];

  dontConfigure = true;
  dontUnpack = true;

  installPhase = ''
    runHook preInstall

    tmp="$(mktemp -d)"

    cd "$tmp"
    mkdir -p classes
    find "${finalAttrs.src}/futures/failureaccess/src" -name '*.java' > sources.txt
    javac --release 8 -d classes @sources.txt
    (
      cd classes
      jar cf "$tmp/failureaccess-${finalAttrs.version}.jar" .
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
