{
  lib,
  fetchgit,
  maven_3_9_14,
}:
let
  version = "0.13.0";
  src = fetchgit {
    url = "https://github.com/commonmark/commonmark-java.git";
    rev = "commonmark-parent-0.13.0";
    hash = "sha256-42oU5aZ+V9Z/QyOqYyYc32z+n8J3j2kF1yQ3xYy2T0A=";
  };
in
maven_3_9_14.buildMavenPackage {
  pname = "commonmark";
  inherit version src;

  mvnHash = "sha256-gvdScxRlS9qwzINNqOhKAH7RhhGO28T7BgbhV7rkbbQ=";

  mvnParameters = "-DskipTests -Dmaven.javadoc.skip=true";

  installPhase = ''
    mkdir -p $out
    mv commonmark/target/commonmark-${version}.jar $out/commonmark-${version}.jar
    mv commonmark/pom.xml $out/commonmark-${version}.pom
    mv commonmark-ext-gfm-tables/target/commonmark-ext-gfm-tables-${version}.jar $out/commonmark-ext-gfm-tables-${version}.jar
    mv commonmark-ext-gfm-tables/pom.xml $out/commonmark-ext-gfm-tables-${version}.pom
    mv commonmark-ext-gfm-strikethrough/target/commonmark-ext-gfm-strikethrough-${version}.jar $out/commonmark-ext-gfm-strikethrough-${version}.jar
    mv commonmark-ext-gfm-strikethrough/pom.xml $out/commonmark-ext-gfm-strikethrough-${version}.pom
  '';

  meta = with lib; {
    description = "commonmark_0_13_0 built from source";
    license = licenses.mit;
    sourceProvenance = with sourceTypes; [ fromSource ];
  };
}
