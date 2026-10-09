{
  lib,
  fetchgit,
  jdk11_headless,
  maven_3_9_14,
}:
let
  version = "1.58.0.0";
  src = fetchgit {
    url = "https://github.com/rtyley/spongycastle.git";
    rev = "sc-v1.58.0.0";
    hash = "sha256-+StbFlywBD3HACFKhx2Nu4zlkKk3bYiAlD3kSLvVWd8=";
  };
in
maven_3_9_14.buildMavenPackage {
  pname = "spongycastle-core";
  inherit version src;
  mvnJdk = jdk11_headless;

  mvnHash = "sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=";
  mvnParameters = "-DskipTests -Dmaven.javadoc.skip=true -pl prov -am";

  installPhase = ''
    mkdir -p $out
    mv core/target/core-${version}.jar $out/core-${version}.jar || true
    mv core/pom.xml $out/core-${version}.pom || true
  '';

  meta = with lib; {
    description = "spongycastle_core_1_58_0_0 built from source";
    license = licenses.mit;
    sourceProvenance = with sourceTypes; [ fromSource ];
  };
}
