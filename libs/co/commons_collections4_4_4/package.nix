{
  lib,
  fetchgit,
  maven_3_9_14,
  jdk11_headless,
}:
let
  version = "4.4";
  src = fetchgit {
    url = "https://github.com/apache/commons-collections.git";
    rev = "commons-commons-collections-4.4";
    hash = "sha256-kikorxJdmPv0TErbN3TEuVnqR4kAG+/0TLx3Cyd8edo=";
  };
in
maven_3_9_14.buildMavenPackage {
  pname = "commons-collections4";
  inherit version src;
  mvnJdk = jdk11_headless;

  mvnHash = "sha256-3ioR/IoGBZxIXAI/N2Eg3OPr9bll0ePPUGJ4wR2KwBo=";

  mvnParameters = "-DskipTests -Dmaven.javadoc.skip=true";

  installPhase = ''
    mkdir -p $out
    mv target/commons-collections4-4.4.jar $out/commons-collections4-4.4.jar
    mv pom.xml $out/commons-collections4-4.4.pom

  '';

  meta = with lib; {
    description = "commons_collections4_4_4 built from source";
    license = licenses.mit;
    sourceProvenance = with sourceTypes; [ fromSource ];
  };
}
