{
  lib,
  fetchgit,
  jdk11_headless,
  maven_3_9_14,
}:
let
  version = "6.5.1";
  src = fetchgit {
    url = "https://github.com/FasterXML/woodstox.git";
    rev = "woodstox-core-6.5.1";
    hash = "sha256-8QRF1LgmiITfCG+9WNK+g+lU6rgJcBuFAPWcg0ngZUs=";
  };
in
maven_3_9_14.buildMavenPackage {
  pname = "woodstox-core";
  inherit version src;
  mvnJdk = jdk11_headless;

  mvnHash = "sha256-GxBzEjr5i2b+YghPyMR46h42HhpkI0sFKkE7XYYUbB4=";
  mvnParameters = "-DskipTests -Dmaven.javadoc.skip=true";

  installPhase = ''
    mkdir -p $out
    mv target/woodstox-core-${version}.jar $out/woodstox-core-${version}.jar || true
    mv pom.xml $out/woodstox-core-${version}.pom || true
  '';

  meta = with lib; {
    description = "woodstox_core_6_5_1 built from source";
    license = licenses.asl20;
    sourceProvenance = with sourceTypes; [ fromSource ];
  };
}
