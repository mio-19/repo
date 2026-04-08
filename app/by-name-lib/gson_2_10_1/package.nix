{
  lib,
  maven,
  fetchFromGitHub,
  jdk17,
}:

maven.buildMavenPackage rec {
  pname = "gson";
  version = "2.10.1";

  src = fetchFromGitHub {
    owner = "google";
    repo = "gson";
    tag = "gson-parent-${version}";
    hash = "sha256-Hjex840nPoJ99l41VeMa9Eiq81QZOEYB2MGvdzQwMus=";
  };

  sourceRoot = "${src.name}/gson";

  mvnJdk = jdk17;
  mvnHash = "sha256-q4aUrZlp8Bpg2T2i/vtWweR1GyJSpO9ICoMbEqztm5o=";

  mvnParameters = "-Dspotless.check.skip=true -Dmaven.javadoc.skip=true";

  installPhase = ''
    runHook preInstall

    mkdir -p $out
    cp ${src}/pom.xml $out/gson-parent-${version}.pom
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
