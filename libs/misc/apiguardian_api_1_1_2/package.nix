{
  lib,
  fetchgit,
  jdk11_headless,
  maven_3_9_14,
}:
let
  version = "1.1.2";
  src = fetchgit {
    url = "https://github.com/apiguardian-team/apiguardian.git";
    rev = "r1.1.2";
    hash = "sha256-3KOLE2XcbSpGr3iXFY6vVt4PFbkCpLT1SK0oPrbjfWU=";
  };
in
maven_3_9_14.buildMavenPackage {
  pname = "apiguardian-api";
  inherit version src;
  mvnJdk = jdk11_headless;

  mvnHash = "sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=";
  mvnParameters = "-DskipTests -Dmaven.javadoc.skip=true";
  
  installPhase = ''
    mkdir -p $out
    mv target/apiguardian-api-${version}.jar $out/apiguardian-api-${version}.jar || true
    mv pom.xml $out/apiguardian-api-${version}.pom || true
  '';

  meta = with lib; {
    description = "apiguardian_api_1_1_2 built from source";
    license = licenses.asl20;
    sourceProvenance = with sourceTypes; [ fromSource ];
  };
}
