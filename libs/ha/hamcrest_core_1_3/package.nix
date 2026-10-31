{
  lib,
  fetchgit,
  jdk11_headless,
  maven_3_9_14,
}:
let
  version = "1.3";
  src = fetchgit {
    url = "https://github.com/hamcrest/JavaHamcrest.git";
    rev = "hamcrest-java-1.3";
    hash = "sha256-w7BlZH9KfPBfh0TUUGD/IIY/4JNg+KXYxlCF0fLs3Zk=";
  };
in
maven_3_9_14.buildMavenPackage {
  pname = "hamcrest-core";
  inherit version src;
  mvnJdk = jdk11_headless;

  mvnHash = "sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=";
  mvnParameters = "-DskipTests -Dmaven.javadoc.skip=true";

  installPhase = ''
    mkdir -p $out
    mv hamcrest-core/target/hamcrest-core-${version}.jar $out/hamcrest-core-${version}.jar || true
    mv hamcrest-core/pom.xml $out/hamcrest-core-${version}.pom || true
  '';

  meta = with lib; {
    description = "hamcrest_core_1_3 built from source";
    license = licenses.mit;
    sourceProvenance = with sourceTypes; [ fromSource ];
  };
}
