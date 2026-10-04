{
  lib,
  fetchgit,
  maven_3_9_14,
}:
let
  version = "3.6.1";
  src = fetchgit {
    url = "https://github.com/apache/commons-math.git";
    rev = "MATH_3_6_1";
    hash = "sha256-NslPIw9kksS4AeHQ5PlOhHiBivj0gQO/voZz0/kIycw=";
  };
in
maven_3_9_14.buildMavenPackage {
  pname = "commons-math3";
  inherit version src;
  
  mvnHash = "sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=";
  
  mvnParameters = "-DskipTests -Dmaven.javadoc.skip=true";
  
  installPhase = ''
    mkdir -p $out
    mv target/commons-math3-3.6.1.jar $out/commons-math3-3.6.1.jar
    mv pom.xml $out/commons-math3-3.6.1.pom

  '';

  meta = with lib; {
    description = "commons_math3_3_6_1 built from source";
    license = licenses.mit;
    sourceProvenance = with sourceTypes; [ fromSource ];
  };
}
