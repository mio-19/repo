{
  lib,
  fetchgit,
  jdk11_headless,
  maven_3_9_14,
}:
let
  version = "0.21.0";
  src = fetchgit {
    url = "https://github.com/commonmark/commonmark-java.git";
    rev = "commonmark-parent-0.21.0";
    hash = "sha256-xhGoLvsnb9yGGF0BMhItTIwzcYTJiq2V34GkUZirPfg=";
  };
in
maven_3_9_14.buildMavenPackage {
  pname = "commonmark";
  inherit version src;
  mvnJdk = jdk11_headless;

  mvnHash = "sha256-Xyj2mEGs9AzaV0JAdu2mozVfPHyJngICjVc73PBPlZE=";
  mvnParameters = "-DskipTests -Dmaven.javadoc.skip=true";

  installPhase = ''
    mkdir -p $out
    mv commonmark/target/commonmark-${version}.jar $out/commonmark-${version}.jar
    mv commonmark/pom.xml $out/commonmark-${version}.pom
    
    mv commonmark-ext-gfm-tables/target/commonmark-ext-gfm-tables-${version}.jar $out/commonmark-ext-gfm-tables-${version}.jar
    mv commonmark-ext-gfm-tables/pom.xml $out/commonmark-ext-gfm-tables-${version}.pom

    mv commonmark-ext-gfm-strikethrough/target/commonmark-ext-gfm-strikethrough-${version}.jar $out/commonmark-ext-gfm-strikethrough-${version}.jar
    mv commonmark-ext-gfm-strikethrough/pom.xml $out/commonmark-ext-gfm-strikethrough-${version}.pom
    
    mv commonmark-ext-autolink/target/commonmark-ext-autolink-${version}.jar $out/commonmark-ext-autolink-${version}.jar
    mv commonmark-ext-autolink/pom.xml $out/commonmark-ext-autolink-${version}.pom
  '';

  meta = with lib; {
    description = "commonmark_0_21_0 built from source";
    license = licenses.mit;
    sourceProvenance = with sourceTypes; [ fromSource ];
  };
}
