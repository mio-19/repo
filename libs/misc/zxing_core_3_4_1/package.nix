{
  lib,
  fetchgit,
  jdk11_headless,
  maven_3_9_14,
}:
let
  version = "3.4.1";
  src = fetchgit {
    url = "https://github.com/zxing/zxing.git";
    rev = "zxing-3.4.1";
    hash = "sha256-WjOb0qmPt3xx/D87tilaAUOrL1kowDuYcr/zCn+GjuQ=";
  };
in
maven_3_9_14.buildMavenPackage {
  pname = "zxing-core";
  inherit version src;
  mvnJdk = jdk11_headless;

  mvnHash = "sha256-XQqMbHckCJEJE+1cRn1RAqIEdiRRv9i2/vjXazYvs94=";
  mvnParameters = "-DskipTests -Dmaven.javadoc.skip=true -pl core -am";
  
  installPhase = ''
    mkdir -p $out
    mv core/target/core-${version}.jar $out/core-${version}.jar || true
    mv core/pom.xml $out/core-${version}.pom || true
  '';

  meta = with lib; {
    description = "zxing_core_3_4_1 built from source";
    license = licenses.asl20;
    sourceProvenance = with sourceTypes; [ fromSource ];
  };
}
