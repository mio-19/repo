{
  lib,
  stdenv,
  fetchFromGitHub,
  jdk21,
}:
stdenv.mkDerivation {
  pname = "revanced-jadb-m2";
  version = "1.2.1.1";

  src = fetchFromGitHub {
    owner = "ReVanced";
    repo = "jadb";
    rev = "53d8e8cf31e60a53453139a1a4030e05cd365826";
    hash = "sha256-eLGpJcy1e5cZYGxDxVB8mNsYQQOlOivwHcn9CaIFouQ=";
  };

  nativeBuildInputs = [ jdk21 ];

  dontConfigure = true;

  buildPhase = ''
    runHook preBuild

    mkdir -p build/classes
    find src -name '*.java' > sources.txt
    ${jdk21}/bin/javac -source 1.8 -target 1.8 -d build/classes @sources.txt

    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall

    m2="$out/app/revanced/jadb/1.2.1.1"
    mkdir -p "$m2"
    (
      cd build/classes
      ${jdk21}/bin/jar cf "$m2/jadb-1.2.1.1.jar" .
    )
    install -Dm644 pom.xml "$m2/jadb-1.2.1.1.pom"

    runHook postInstall
  '';

  meta = with lib; {
    description = "ReVanced fork of jadb published to a local Maven repository";
    homepage = "https://github.com/ReVanced/jadb";
    license = licenses.asl20;
    platforms = platforms.unix;
  };
}
