{
  lib,
  fetchgit,
  jdk11_headless,
  maven_3_9_14,
}:
let
  version = "3.25.4";
  src = fetchgit {
    url = "https://github.com/javaparser/javaparser.git";
    rev = "javaparser-parent-${version}";
    hash = "sha256-XZG6J8Zt729JhahINpnJz7DIS2Yss0b3rssA+xQB/iA=";
  };
in
maven_3_9_14.buildMavenPackage {
  pname = "javaparser-core";
  inherit version src;
  mvnJdk = jdk11_headless;

  mvnHash = "sha256-5MxoS+G5xGzMxHniAlq/5VqPk4fl1KCQKCZctUW1BcI=";
  mvnParameters = "-DskipTests -Dmaven.javadoc.skip=true -pl javaparser-core -am";

  installPhase = ''
    mkdir -p $out
    mv javaparser-core/target/javaparser-core-${version}.jar $out/javaparser-core-${version}.jar || true
    mv javaparser-core/pom.xml $out/javaparser-core-${version}.pom || true
  '';

  meta = with lib; {
    description = "javaparser_core_3_25_4 built from source";
    license = licenses.asl20;
    sourceProvenance = with sourceTypes; [ fromSource ];
  };
}
