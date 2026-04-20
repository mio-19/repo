{
  stdenv,
  fetchurl,
  unzip,
  jdk8_headless,
  makeWrapper,
  gradle_4_9_0,
}:
stdenv.mkDerivation rec {
  pname = "gradle-bin";
  version = "4.10.3";

  src = fetchurl {
    url = "https://services.gradle.org/distributions/gradle-${version}-bin.zip";
    sha256 = "0vhqxnk0yj3q9jam5w4kpia70i4h0q4pjxxqwynh3qml0vrcn9l6";
  };

  nativeBuildInputs = [
    unzip
    makeWrapper
  ];

  dontBuild = true;

  installPhase = ''
    mkdir -p $out/libexec/gradle
    cp -rv . $out/libexec/gradle/

    mkdir -p $out/bin
    makeWrapper $out/libexec/gradle/bin/gradle $out/bin/gradle \
      --set-default JAVA_HOME ${jdk8_headless.passthru.home}
  '';

  passthru.fetchDeps = gradle_4_9_0.fetchDeps;
}
