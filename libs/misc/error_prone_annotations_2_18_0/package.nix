{
  lib,
  fetchgit,
  jdk25_headless,
  maven_3_9_14,
}:
let
  version = "2.18.0";
  src = fetchgit {
    url = "https://github.com/google/error-prone.git";
    rev = "v2.18.0";
    hash = "sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=";
  };
in
maven_3_9_14.buildMavenPackage {
  pname = "error_prone_annotations";
  inherit version src;

  mvnHash = "sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=";
  mvnParameters = "-DskipTests -Dmaven.javadoc.skip=true";
  
  preBuild = ''
    cd annotations
  '';

  installPhase = ''
    mkdir -p $out
    mv target/error_prone_annotations-${version}.jar $out/error_prone_annotations-${version}.jar
    mv pom.xml $out/error_prone_annotations-${version}.pom
    mv ../pom.xml $out/error_prone_parent-${version}.pom
  '';

  meta = with lib; {
    description = "error_prone_annotations_2_18_0 built from source";
    license = licenses.mit;
    sourceProvenance = with sourceTypes; [ fromSource ];
  };
}
