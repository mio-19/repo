{
  lib,
  fetchgit,
  jdk11_headless,
  maven_3_9_14,
}:
let
  version = "1.1";
  src = fetchgit {
    url = "https://github.com/google/jimfs.git";
    rev = "v1.1";
    hash = "sha256-gE2ePH+17Fm+EuA2oWWl7LOacYacS6p7/hCX5S7DkIE=";
  };
in
maven_3_9_14.buildMavenPackage {
  pname = "jimfs";
  inherit version src;
  mvnJdk = jdk11_headless;

  mvnHash = "sha256-uK78RhbK3F+zkuHbGvOSZFgkeyXqe2cgtd3gOblml5I=";
  mvnParameters = "-DskipTests -Dmaven.javadoc.skip=true";
  
  installPhase = ''
    mkdir -p $out
    mv jimfs/target/jimfs-${version}.jar $out/jimfs-${version}.jar || true
    mv jimfs/pom.xml $out/jimfs-${version}.pom || true
  '';

  meta = with lib; {
    description = "jimfs_1_1 built from source";
    license = licenses.asl20;
    sourceProvenance = with sourceTypes; [ fromSource ];
  };
}
