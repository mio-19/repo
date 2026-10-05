{
  lib,
  fetchgit,
  jdk11_headless,
  maven_3_9_14,
}:
let
  version = "13.0";
  src = fetchgit {
    url = "https://github.com/JetBrains/java-annotations.git";
    rev = "13.0";
    hash = "sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=";
  };
in
maven_3_9_14.buildMavenPackage {
  pname = "jetbrains-annotations";
  inherit version src;
  mvnJdk = jdk11_headless;

  mvnHash = "sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=";
  mvnParameters = "-DskipTests -Dmaven.javadoc.skip=true";
  
  installPhase = ''
    mkdir -p $out
    mv target/annotations-${version}.jar $out/annotations-${version}.jar || true
    mv pom.xml $out/annotations-${version}.pom || true
  '';

  meta = with lib; {
    description = "jetbrains_annotations_13_0 built from source";
    license = licenses.asl20;
    sourceProvenance = with sourceTypes; [ fromSource ];
  };
}
