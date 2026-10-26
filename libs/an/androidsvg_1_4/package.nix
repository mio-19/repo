{
  lib,
  fetchgit,
  jdk11_headless,
  maven_3_9_14,
}:
let
  version = "1.4";
  src = fetchgit {
    url = "https://github.com/BigBadaboom/androidsvg.git";
    rev = "1.4";
    hash = "sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=";
  };
in
maven_3_9_14.buildMavenPackage {
  pname = "androidsvg";
  inherit version src;
  mvnJdk = jdk11_headless;

  mvnHash = "sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=";
  mvnParameters = "-DskipTests -Dmaven.javadoc.skip=true";

  installPhase = ''
    mkdir -p $out
    mv androidsvg/target/androidsvg-${version}.jar $out/androidsvg-${version}.jar || true
    mv androidsvg/pom.xml $out/androidsvg-${version}.pom || true
  '';

  meta = with lib; {
    description = "androidsvg_1_4 built from source";
    license = licenses.asl20;
    sourceProvenance = with sourceTypes; [ fromSource ];
  };
}
