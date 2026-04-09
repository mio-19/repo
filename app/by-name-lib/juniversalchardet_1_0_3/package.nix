{
  fetchFromGitHub,
  fetchurl,
  jdk21,
  lib,
  stdenv,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "juniversalchardet";
  version = "1.0.3";

  src = fetchFromGitHub {
    owner = "albfernandez";
    repo = "juniversalchardet";
    tag = "v${finalAttrs.version}";
    hash = "sha256-a+cehN7tgScYdzyrLJaD8VzuLLb5Zuj0637kI1ZxgLs=";
  };

  pomFile = fetchurl {
    url = "https://repo.maven.apache.org/maven2/com/googlecode/juniversalchardet/juniversalchardet/1.0.3/juniversalchardet-1.0.3.pom";
    hash = "sha256-eEY5mzXHzWQqmzoADD4tYtBOs3pFR7aTPMixi8wvCGs=";
  };

  nativeBuildInputs = [ jdk21 ];

  dontConfigure = true;
  dontUnpack = true;

  installPhase = ''
    runHook preInstall

    tmp="$(mktemp -d)"
    trap 'rm -rf "$tmp"' EXIT
    cd "$tmp"

    mkdir -p classes
    find "${finalAttrs.src}/src/main/java" -name '*.java' | sort > sources.txt
    ${jdk21}/bin/javac --release 8 -encoding UTF-8 -d classes @sources.txt

    (
      cd classes
      ${jdk21}/bin/jar cf "$tmp/juniversalchardet-${finalAttrs.version}.jar" .
    )

    mkdir -p "$out"
    install -Dm644 "$tmp/juniversalchardet-${finalAttrs.version}.jar" "$out/juniversalchardet-${finalAttrs.version}.jar"
    install -Dm644 "${finalAttrs.pomFile}" "$out/juniversalchardet-${finalAttrs.version}.pom"

    runHook postInstall
  '';

  meta = with lib; {
    description = "Encoding detector library ported from Mozilla universalchardet";
    homepage = "https://github.com/albfernandez/juniversalchardet";
    license = with licenses; [
      mpl11
      gpl3Plus
      lgpl3Plus
    ];
    platforms = platforms.unix;
  };
})
