{
  fetchurl,
  jdk21_headless,
  lib,
  stdenv,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "fastutil";
  version = "7.2.1";

  src = fetchurl {
    url = "https://repo.maven.apache.org/maven2/it/unimi/dsi/fastutil/${finalAttrs.version}/fastutil-${finalAttrs.version}-sources.jar";
    hash = "sha256-TcWqnsalUZkOujYP3jRhmdHLcZ4Lwcy4GymJKoa0U4A=";
  };

  pom = fetchurl {
    url = "https://repo.maven.apache.org/maven2/it/unimi/dsi/fastutil/${finalAttrs.version}/fastutil-${finalAttrs.version}.pom";
    hash = "sha256-q1AqYzGbrUEhPTFtYc9JeE2eljHeZIS99mZbqi+tYYw=";
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
    find it -name '*.java' ! -name '*Test.java' ! -name '*Tests.java' | sort > sources.txt
    javac --release 8 -d classes @sources.txt

    (
      cd classes
      jar cf "$tmp/fastutil-${finalAttrs.version}.jar" .
    )

    mkdir -p "$out"
    install -Dm644 "$tmp/fastutil-${finalAttrs.version}.jar" "$out/fastutil-${finalAttrs.version}.jar"
    install -Dm644 "$pom" "$out/fastutil-${finalAttrs.version}.pom"

    runHook postInstall
  '';

  meta = with lib; {
    description = "Type-specific Java collections framework";
    homepage = "https://fastutil.di.unimi.it/";
    license = licenses.asl20;
    platforms = platforms.unix;
  };
})
