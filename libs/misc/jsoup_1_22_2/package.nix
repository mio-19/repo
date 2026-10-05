{
  lib,
  fetchgit,
  maven_3_9_14,
}:
let
  version = "1.22.2";
  src = fetchgit {
    url = "https://github.com/jhy/jsoup.git";
    rev = "jsoup-1.22.2";
    hash = "sha256-Kb+KoGNghAJgEiTX2S+YUYjJTooJvTuZE9wUyWYNbqE=";
  };
in
maven_3_9_14.buildMavenPackage {
  pname = "jsoup";
  inherit version src;

  mvnHash = "sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=";
  mvnParameters = "-DskipTests -Dmaven.javadoc.skip=true";
  preBuild = "export SOURCE_DATE_EPOCH=315532802";

  installPhase = ''
    mkdir -p $out
    mv target/jsoup-${version}.jar $out/jsoup-${version}.jar
    mv pom.xml $out/jsoup-${version}.pom
  '';

  meta = with lib; {
    description = "jsoup_1_22_2 built from source";
    license = licenses.mit;
    sourceProvenance = with sourceTypes; [ fromSource ];
  };
}
