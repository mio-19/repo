{
  lib,
  fetchgit,
  maven_3_9_14,
}:
let
  version = "1.16.1";
  src = fetchgit {
    url = "https://github.com/jhy/jsoup.git";
    rev = "refs/tags/jsoup-\${version}";
    hash = "sha256-cIEEHIlaKXIuqja+XNA+5q3H+MMNSuuKcP4Z2wCDxwA=";
  };
in
maven_3_9_14.buildMavenPackage {
  pname = "jsoup";
  inherit version src;

  mvnHash = "sha256-oOo/EdOsuN6cj5VrbZQliZT3ykyBtCHvc48MZ7/rNAg=";

  mvnParameters = "-DskipTests -Dmaven.javadoc.skip=true";

  installPhase = ''
    mkdir -p $out
    mv target/jsoup-\${version}.jar $out/
    mv pom.xml $out/jsoup-\${version}.pom
  '';

  meta = with lib; {
    description = "Java HTML Parser";
    homepage = "https://jsoup.org/";
    license = licenses.mit;
    sourceProvenance = with sourceTypes; [ fromSource ];
  };
}
