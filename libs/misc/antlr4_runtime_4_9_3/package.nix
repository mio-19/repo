{
  lib,
  fetchgit,
  jdk11_headless,
  maven_3_9_14,
}:
let
  version = "4.9.3";
  src = fetchgit {
    url = "https://github.com/antlr/antlr4.git";
    rev = "4.9.3";
    hash = "sha256-FQeb1P9/QLZtw9leWvnx0DshEqgqQI3LCpieybFjw6k=";
  };
in
maven_3_9_14.buildMavenPackage {
  pname = "antlr4-runtime";
  inherit version src;
  mvnJdk = jdk11_headless;

  mvnHash = "sha256-UJ0tiesM2ODMACp834N4ZqeCiLjRR/2AX0/nGwChIVY=";
  mvnParameters = "-DskipTests -Dmaven.javadoc.skip=true -pl runtime/Java -am";
  
  installPhase = ''
    mkdir -p $out
    mv runtime/Java/target/antlr4-runtime-${version}.jar $out/antlr4-runtime-${version}.jar || true
    mv runtime/Java/pom.xml $out/antlr4-runtime-${version}.pom || true
  '';

  meta = with lib; {
    description = "antlr4_runtime_4_9_3 built from source";
    license = licenses.bsd3;
    sourceProvenance = with sourceTypes; [ fromSource ];
  };
}
