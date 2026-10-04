{
  lib,
  fetchgit,
  jdk25_headless,
  maven_3_9_14,
}:
let
  version = "2.2";
  src = fetchgit {
    url = "https://bitbucket.org/snakeyaml/snakeyaml.git";
    rev = "snakeyaml-2.2";
    hash = "sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=";
  };
in
maven_3_9_14.buildMavenPackage {
  pname = "snakeyaml";
  inherit version src;

  mvnHash = "sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=";
  mvnParameters = "-DskipTests -Dmaven.javadoc.skip=true";

  installPhase = ''
    mkdir -p $out
    mv target/snakeyaml-${version}.jar $out/snakeyaml-${version}.jar
    mv pom.xml $out/snakeyaml-${version}.pom
  '';

  meta = with lib; {
    description = "snakeyaml_2_2 built from source";
    license = licenses.mit;
    sourceProvenance = with sourceTypes; [ fromSource ];
  };
}
