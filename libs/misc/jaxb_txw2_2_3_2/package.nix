{
  lib,
  fetchgit,
  jdk11_headless,
  maven_3_9_14,
}:
let
  version = "2.3.2";
  src = fetchgit {
    url = "https://github.com/eclipse-ee4j/jaxb-ri.git";
    rev = "2.3.2-RI";
    hash = "sha256-zdJwefYclFVJSWTVvZnjg07BsGnd0EqjB3Im+ZMrE5s=";
  };
in
maven_3_9_14.buildMavenPackage {
  pname = "txw2";
  inherit version src;
  mvnJdk = jdk11_headless;

  mvnHash = "sha256-mF/dhw7Jcq+lG9TgiCuhLE6UA94t2PvXtfQvB7PNDRw=";
  mvnParameters = "-DskipTests -Dmaven.javadoc.skip=true -pl txw/compiler -am";
  sourceRoot = "${src.name}/jaxb-ri";

  installPhase = ''
    mkdir -p $out
    mv txw/runtime/target/txw2-${version}.jar $out/txw2-${version}.jar || true
    mv txw/runtime/pom.xml $out/txw2-${version}.pom || true
  '';

  meta = with lib; {
    description = "jaxb_txw2_2_3_2 built from source";
    license = licenses.mit;
    sourceProvenance = with sourceTypes; [ fromSource ];
  };
}
