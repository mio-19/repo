{
  lib,
  fetchgit,
  jdk11_headless,
  maven_3_9_14,
}:
let
  version = "8.12.34";
  src = fetchgit {
    url = "https://github.com/google/libphonenumber.git";
    rev = "v8.12.34";
    hash = "sha256-Q8BM1Qe86WwqeGfAwzrVdw4yB490+I19mlEJ0ngWNYc=";
  };
in
maven_3_9_14.buildMavenPackage {
  pname = "libphonenumber";
  inherit version src;
  mvnJdk = jdk11_headless;

  mvnHash = "sha256-aZhwl+Cms8XdK1t7Qse4BLXAx6vsfLRuM2tlmibTi9I=";
  mvnParameters = "-DskipTests -Dmaven.javadoc.skip=true -pl java/libphonenumber -am";
  
  installPhase = ''
    mkdir -p $out
    mv java/libphonenumber/target/libphonenumber-${version}.jar $out/libphonenumber-${version}.jar || true
    mv java/libphonenumber/pom.xml $out/libphonenumber-${version}.pom || true
    
  '';

  meta = with lib; {
    description = "libphonenumber_8_12_34 built from source";
    license = licenses.asl20;
    sourceProvenance = with sourceTypes; [ fromSource ];
  };
}
