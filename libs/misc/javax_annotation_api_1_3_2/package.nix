{
  lib,
  fetchgit,
  jdk11_headless,
  maven_3_9_14,
}:
let
  version = "1.3.2";
  src = fetchgit {
    url = "https://github.com/javaee/javax.annotation.git";
    rev = "1.3.2";
    hash = "sha256-8V0aNgGAcMGKRPwL1cVGUM6RK/P+G1Gz5rTO50n1GKg=";
  };
in
maven_3_9_14.buildMavenPackage {
  pname = "javax-annotation-api";
  inherit version src;
  mvnJdk = jdk11_headless;

  mvnHash = "sha256-6kBwdctT8FaGD39rw29VCFMTAzTekte4C7MzyYYBliU=";
  mvnParameters = "-DskipTests -Dmaven.javadoc.skip=true";

  installPhase = ''
    mkdir -p $out
    mv target/javax.annotation-api-${version}.jar $out/javax.annotation-api-${version}.jar
    mv pom.xml $out/javax.annotation-api-${version}.pom
  '';

  meta = with lib; {
    description = "javax_annotation_api_1_3_2 built from source";
    license = licenses.mit;
    sourceProvenance = with sourceTypes; [ fromSource ];
  };
}
