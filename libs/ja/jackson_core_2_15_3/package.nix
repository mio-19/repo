{
  lib,
  fetchgit,
  maven_3_9_14,
}:
let
  version = "2.15.3";
  src = fetchgit {
    url = "https://github.com/FasterXML/jackson-core.git";
    rev = "jackson-core-2.15.3";
    hash = "sha256-2ZThLJHUvniX6duT1Y0Sy3o0SzknWDxCPNDJNDGLyKM=";
  };
in
maven_3_9_14.buildMavenPackage {
  pname = "jackson-core";
  inherit version src;

  mvnHash = "sha256-p4rLMJMdSbQHygkDuLflUZicfBqkKNho0clJqjXdKJs=";

  mvnParameters = "-DskipTests -Dmaven.javadoc.skip=true";

  installPhase = ''
    mkdir -p $out
    mv target/jackson-core-2.15.3.jar $out/jackson-core-2.15.3.jar
    mv pom.xml $out/jackson-core-2.15.3.pom

  '';

  meta = with lib; {
    description = "jackson_core_2_15_3 built from source";
    license = licenses.mit;
    sourceProvenance = with sourceTypes; [ fromSource ];
  };
}
