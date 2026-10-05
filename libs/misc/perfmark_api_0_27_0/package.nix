{
  lib,
  fetchgit,
  jdk25_headless,
  maven_3_9_14,
}:
let
  version = "0.27.0";
  src = fetchgit {
    url = "https://github.com/perfmark/perfmark.git";
    rev = "v0.27.0";
    hash = "sha256-wm9B3MMHm7YJUIX8lVkyLdWdlrH6Hnl8MHKTtBBbfQM=";
  };
in
maven_3_9_14.buildMavenPackage {
  pname = "perfmark-api";
  inherit version src;

  mvnHash = "sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=";
  mvnParameters = "-DskipTests -Dmaven.javadoc.skip=true";

  installPhase = ''
    mkdir -p $out
    mv api/target/perfmark-api-${version}.jar $out/perfmark-api-${version}.jar
    mv api/pom.xml $out/perfmark-api-${version}.pom
  '';

  meta = with lib; {
    description = "perfmark_api_0_27_0 built from source";
    license = licenses.mit;
    sourceProvenance = with sourceTypes; [ fromSource ];
  };
}
