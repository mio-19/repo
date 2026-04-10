{
  fetchurl,
  jdk21_headless,
  lib,
  stdenv,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "brotli-dec";
  version = "0.1.2";

  src = fetchurl {
    url = "https://repo.maven.apache.org/maven2/org/brotli/dec/${finalAttrs.version}/dec-${finalAttrs.version}-sources.jar";
    hash = "sha256-BkrB5B9HXB/QR5tlBfRLbjuwRLlIvdx11WpJbruF+8M=";
  };

  pom = fetchurl {
    url = "https://repo.maven.apache.org/maven2/org/brotli/dec/${finalAttrs.version}/dec-${finalAttrs.version}.pom";
    hash = "sha256-HT2yjgAeuaAXMtDJi+Bir5r1NtlCiXoMk3mEr4tCKMA=";
  };

  nativeBuildInputs = [ jdk21_headless ];

  dontConfigure = true;
  dontUnpack = true;

  installPhase = ''
    runHook preInstall

    tmp="$(mktemp -d)"
    trap 'rm -rf "$tmp"' EXIT
    cd "$tmp"
    jar xf "$src"

    mkdir -p classes
    find org -name '*.java' | sort > sources.txt
    javac --release 8 -d classes @sources.txt

    (
      cd classes
      jar cf "$tmp/dec-${finalAttrs.version}.jar" .
    )

    mkdir -p "$out"
    install -Dm644 "$tmp/dec-${finalAttrs.version}.jar" "$out/dec-${finalAttrs.version}.jar"
    install -Dm644 "$pom" "$out/dec-${finalAttrs.version}.pom"

    runHook postInstall
  '';

  meta = with lib; {
    description = "Brotli decoder for Java";
    homepage = "https://github.com/google/brotli";
    license = licenses.mit;
    platforms = platforms.unix;
  };
})
