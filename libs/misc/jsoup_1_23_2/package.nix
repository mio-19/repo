{
  lib,
  fetchgit,
  jdk25_headless,
  maven_3_9_14,
}:
let
  version = "1.23.2";
  src = fetchgit {
    url = "https://github.com/jhy/jsoup.git";
    rev = "jsoup-1.23.2";
    hash = "sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=";
  };
in
maven_3_9_14.buildMavenPackage {
  pname = "jsoup";
  inherit version src;

  mvnHash = "sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=";
  mvnParameters = "-DskipTests -Dmaven.javadoc.skip=true";

  installPhase = ''
    mkdir -p $out
    mv target/jsoup-${version}.jar $out/jsoup-${version}.jar
    mv pom.xml $out/jsoup-${version}.pom
  '';

  meta = with lib; {
    description = "jsoup_1_23_2 built from source";
    license = licenses.mit;
    sourceProvenance = with sourceTypes; [ fromSource ];
  };
}
