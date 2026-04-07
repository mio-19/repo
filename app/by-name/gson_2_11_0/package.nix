{
  lib,
  maven,
  fetchFromGitHub,
  jdk17,
}:

maven.buildMavenPackage rec {
  pname = "gson";
  version = "2.11.0";

  src = fetchFromGitHub {
    owner = "google";
    repo = "gson";
    tag = "gson-parent-${version}";
    hash = "sha256-HyQCgviEfzLjoxE0MbmbK0Ht52DWeWrq9P8ma/0kdSQ=";
  };

  sourceRoot = "${src.name}/gson";

  mvnJdk = jdk17;
  mvnHash = "sha256-el60eCmPyP6KK86BrPA/7kCc4ZN3OckR8uoHzVWENFY=";

  mvnParameters = "-Dspotless.check.skip=true -Dmaven.javadoc.skip=true";

  installPhase = ''
    runHook preInstall

    mkdir -p $out
    cp target/gson-${version}.jar $out/
    cp pom.xml $out/gson-${version}.pom

    runHook postInstall
  '';

  meta = with lib; {
    description = "Java serialization and deserialization library for JSON";
    homepage = "https://github.com/google/gson";
    license = licenses.asl20;
  };
}
