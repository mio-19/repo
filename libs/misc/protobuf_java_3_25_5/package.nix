{
  lib,
  fetchgit,
  jdk25_headless,
  maven_3_9_14,
}:
let
  version = "3.25.5";
  src = fetchgit {
    url = "https://github.com/protocolbuffers/protobuf.git";
    rev = "v3.25.5";
    hash = "sha256-DFLlk4T8ODo3lmvrANlkIsrmDXZHmqMPTYxDWaz56qA=";
  };
in
maven_3_9_14.buildMavenPackage {
  pname = "protobuf-java";
  inherit version src;

  mvnHash = "sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=";
  mvnParameters = "-DskipTests -Dmaven.javadoc.skip=true";

  sourceRoot = "${src.name}/java";

  installPhase = ''
    mkdir -p $out
    mv core/target/protobuf-java-${version}.jar $out/protobuf-java-${version}.jar
    mv core/pom.xml $out/protobuf-java-${version}.pom
  '';

  meta = with lib; {
    description = "protobuf_java_3_25_5 built from source";
    license = licenses.mit;
    sourceProvenance = with sourceTypes; [ fromSource ];
  };
}
