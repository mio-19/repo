{
  brotli_dec_0_1_2,
  fetchFromGitHub,
  jdk21_headless,
  lib,
  stdenv,
  xz_java_1_6,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "commons-compress";
  version = "1.14";

  src = fetchFromGitHub {
    owner = "apache";
    repo = "commons-compress";
    tag = "rel/1.14";
    hash = "sha256-ZDumFi1THSgrldqjA8dpW6oVImA1YQynmKrYAePYcak=";
  };

  nativeBuildInputs = [ jdk21_headless ];

  dontConfigure = true;
  dontUnpack = true;

  installPhase = ''
    runHook preInstall

    tmp="$(mktemp -d)"
    trap 'rm -rf "$tmp"' EXIT
    cd "$tmp"

    mkdir -p classes
    find "${finalAttrs.src}/src/main/java" -name '*.java' | sort > sources.txt
    javac --release 8 \
      -cp "${brotli_dec_0_1_2}/dec-${brotli_dec_0_1_2.version}.jar:${xz_java_1_6}/xz-${xz_java_1_6.version}.jar" \
      -d classes \
      @sources.txt

    (
      cd classes
      jar cf "$tmp/commons-compress-${finalAttrs.version}.jar" .
    )

    mkdir -p "$out"
    install -Dm644 "$tmp/commons-compress-${finalAttrs.version}.jar" "$out/commons-compress-${finalAttrs.version}.jar"
    install -Dm644 "${finalAttrs.src}/pom.xml" "$out/commons-compress-${finalAttrs.version}.pom"

    runHook postInstall
  '';

  meta = with lib; {
    description = "Apache Commons Compress";
    homepage = "https://commons.apache.org/proper/commons-compress/";
    license = licenses.asl20;
    platforms = platforms.unix;
  };
})
