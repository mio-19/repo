{
  lib,
  fetchgit,
  maven_3_9_14,
}:
let
  version = "2.15.3";
  src = fetchgit {
    url = "https://github.com/FasterXML/jackson-databind.git";
    rev = "jackson-databind-2.15.3";
    hash = "sha256-ttxL9WE9r1G+ADKpoqdPz4OfUzKtFsUkCv8oQD9XuL8=";
  };
in
maven_3_9_14.buildMavenPackage {
  pname = "jackson-databind";
  inherit version src;

  mvnHash = "sha256-SWsyc1dL4+FGTvQdCsiXxMn509dgGX4VqbpMagnfVkY=";

  mvnParameters = "-DskipTests -Dmaven.javadoc.skip=true";

  installPhase = ''
    mkdir -p $out
    mv target/jackson-databind-2.15.3.jar $out/jackson-databind-2.15.3.jar
    mv pom.xml $out/jackson-databind-2.15.3.pom

  '';

  meta = with lib; {
    description = "jackson_databind_2_15_3 built from source";
    license = licenses.mit;
    sourceProvenance = with sourceTypes; [ fromSource ];
  };
}
