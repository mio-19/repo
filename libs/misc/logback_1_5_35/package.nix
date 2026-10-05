{
  lib,
  fetchgit,
  jdk17_headless,
  maven_3_9_14,
}:
let
  version = "1.5.35";
  src = fetchgit {
    url = "https://github.com/qos-ch/logback.git";
    rev = "v_1.5.35";
    hash = "sha256-eJY4XG6oMNEWIsG5We/L9Kqw5Nt7OI5aUedG9XaRcQc=";
  };
in
maven_3_9_14.buildMavenPackage {
  pname = "logback";
  inherit version src;
  mvnJdk = jdk17_headless;

  mvnHash = "sha256-PMfNwxMBlavXRxTFZTL6iubABl1lZJRjZSVtUFYVvIY=";
  mvnParameters = "-DskipTests -Dmaven.javadoc.skip=true";
  
  installPhase = ''
    mkdir -p $out
    mv logback-core/target/logback-core-${version}.jar $out/logback-core-${version}.jar || true
    mv logback-core/pom.xml $out/logback-core-${version}.pom || true
    mv logback-classic/target/logback-classic-${version}.jar $out/logback-classic-${version}.jar || true
    mv logback-classic/pom.xml $out/logback-classic-${version}.pom || true
  '';

  meta = with lib; {
    description = "logback_1_5_35 built from source";
    license = licenses.asl20;
    sourceProvenance = with sourceTypes; [ fromSource ];
  };
}
