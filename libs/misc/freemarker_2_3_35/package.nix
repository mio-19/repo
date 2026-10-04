{
  lib,
  fetchgit,
  jdk11_headless,
  maven_3_9_14,
}:
let
  version = "2.3.35";
  src = fetchgit {
    url = "https://github.com/apache/freemarker.git";
    rev = "v2.3.35";
    hash = "sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=";
  };
in
maven_3_9_14.buildMavenPackage {
  pname = "freemarker";
  inherit version src;
  mvnJdk = jdk11_headless;

  mvnHash = "sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=";
  mvnParameters = "-DskipTests -Dmaven.javadoc.skip=true";

  installPhase = ''
    mkdir -p $out
    mv freemarker/target/freemarker-${version}.jar $out/freemarker-${version}.jar
    mv freemarker/pom.xml $out/freemarker-${version}.pom
  '';

  meta = with lib; {
    description = "freemarker_2_3_35 built from source";
    license = licenses.mit;
    sourceProvenance = with sourceTypes; [ fromSource ];
  };
}
