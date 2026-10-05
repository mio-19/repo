{
  lib,
  fetchgit,
  maven_3_9_14,
}:
let
  version = "1.0.4";
  src = fetchgit {
    url = "https://github.com/reactive-streams/reactive-streams-jvm.git";
    rev = "v1.0.4";
    hash = "sha256-03WPFxkk8SoaP75mpaalIlTemDRTy5n0Pvfe3JLrg2g=";
  };
in
maven_3_9_14.buildMavenPackage {
  pname = "reactive-streams";
  inherit version src;

  mvnHash = "sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=";
  mvnParameters = "-DskipTests -Dmaven.javadoc.skip=true";

  installPhase = ''
    mkdir -p $out
    mv api/target/reactive-streams-${version}.jar $out/reactive-streams-${version}.jar
    mv api/pom.xml $out/reactive-streams-${version}.pom
  '';

  meta = with lib; {
    description = "reactive_streams_1_0_4 built from source";
    license = licenses.mit;
    sourceProvenance = with sourceTypes; [ fromSource ];
  };
}
