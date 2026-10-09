{
  lib,
  fetchgit,
  jdk11_headless,
  maven_3_9_14,
}:
let
  version = "1.2.16";
  src = fetchgit {
    url = "https://github.com/eclipse-ee4j/fastinfoset.git";
    rev = "1.2.16";
    hash = "sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=";
  };
in
maven_3_9_14.buildMavenPackage {
  pname = "fastinfoset";
  inherit version src;
  mvnJdk = jdk11_headless;

  mvnHash = "sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=";
  mvnParameters = "-DskipTests -Dmaven.javadoc.skip=true";

  installPhase = ''
    mkdir -p $out
    mv code/fastinfoset/target/FastInfoset-${version}.jar $out/FastInfoset-${version}.jar || true
    mv code/fastinfoset/pom.xml $out/FastInfoset-${version}.pom || true
  '';

  meta = with lib; {
    description = "fastinfoset_1_2_16 built from source";
    license = licenses.asl20;
    sourceProvenance = with sourceTypes; [ fromSource ];
  };
}
