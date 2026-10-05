{
  lib,
  fetchgit,
  jdk11_headless,
  maven_3_9_14,
}:
let
  version = "2.11.0";
  src = fetchgit {
    url = "https://github.com/google/gson.git";
    rev = "gson-parent-2.11.0";
    hash = "sha256-HyQCgviEfzLjoxE0MbmbK0Ht52DWeWrq9P8ma/0kdSQ=";
  };
in
maven_3_9_14.buildMavenPackage {
  pname = "gson";
  inherit version src;
  mvnJdk = jdk11_headless;

  mvnHash = "sha256-9RCH3CRTMvoeaR0utyFYKQhgmUVLOfShcrsXapA5EeU=";
  mvnParameters = "-DskipTests -Dmaven.javadoc.skip=true";

  installPhase = ''
    mkdir -p $out
    mv gson/target/gson-${version}.jar $out/gson-${version}.jar
    mv gson/pom.xml $out/gson-${version}.pom
    mv pom.xml $out/gson-parent-${version}.pom
  '';

  meta = with lib; {
    description = "gson_2_11_0 built from source";
    license = licenses.mit;
    sourceProvenance = with sourceTypes; [ fromSource ];
  };
}
