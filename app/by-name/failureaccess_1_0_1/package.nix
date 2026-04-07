{
  fetchurl,
  jdk21,
  lib,
  stdenv,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "failureaccess";
  version = "1.0.1";

  src = fetchurl {
    url = "https://repo.maven.apache.org/maven2/com/google/guava/failureaccess/1.0.1/failureaccess-1.0.1-sources.jar";
    hash = "sha256-CSNG7ruxZXtRqnSFoka/YCu0ZMwLDi4cfnIB+tzh6Y8=";
  };

  pom = fetchurl {
    url = "https://repo.maven.apache.org/maven2/com/google/guava/failureaccess/1.0.1/failureaccess-1.0.1.pom";
    hash = "sha256-6WBCznj+y6DaK+lkUilHyHtAopG1/TzWcqQ0kkEDxLk=";
  };

  parentPom = fetchurl {
    url = "https://repo.maven.apache.org/maven2/com/google/guava/guava-parent/26.0-android/guava-parent-26.0-android.pom";
    hash = "sha256-+GmKtGypls6InBr8jKTyXrisawNNyJjUWDdCNgAWzAQ=";
  };

  nativeBuildInputs = [ jdk21 ];

  dontConfigure = true;
  dontUnpack = true;

  installPhase = ''
    runHook preInstall

    tmp="$(mktemp -d)"
    trap 'rm -rf "$tmp"' EXIT
    cd "$tmp"
    ${jdk21}/bin/jar xf "$src"
    mkdir -p classes
    find . -name '*.java' | sort > sources.txt
    ${jdk21}/bin/javac --release 8 -d classes @sources.txt
    (
      cd classes
      ${jdk21}/bin/jar cf "$tmp/failureaccess-${finalAttrs.version}.jar" .
    )

    mkdir -p "$out"
    install -Dm644 "$tmp/failureaccess-${finalAttrs.version}.jar" "$out/failureaccess-${finalAttrs.version}.jar"
    install -Dm644 "$pom" "$out/failureaccess-${finalAttrs.version}.pom"
    install -Dm644 "$parentPom" "$out/guava-parent-26.0-android.pom"

    runHook postInstall
  '';

  meta = with lib; {
    description = "Guava internal future failure access helper";
    homepage = "https://github.com/google/guava";
    license = licenses.asl20;
    platforms = platforms.unix;
  };
})
