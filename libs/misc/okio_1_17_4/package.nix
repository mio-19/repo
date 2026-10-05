{
  lib,
  fetchgit,
  jdk11_headless,
  maven_3_9_14,
}:
let
  version = "1.17.4";
  src = fetchgit {
    url = "https://github.com/square/okio.git";
    rev = "okio-parent-1.17.4";
    hash = "sha256-iofH62RrGOJ5i6GXEPWgfPZZZ/6ZrqCQzn49jR4kuDg=";
  };
in
maven_3_9_14.buildMavenPackage {
  pname = "okio";
  inherit version src;
  mvnJdk = jdk11_headless;

  mvnHash = "sha256-iofH62RrGOJ5i6GXEPWgfPZZZ/6ZrqCQzn49jR4kuDg=";
  mvnParameters = "-DskipTests -Dmaven.javadoc.skip=true -pl okio -am";
  
  installPhase = ''
    mkdir -p $out
    mv okio/target/okio-${version}.jar $out/okio-${version}.jar || true
    mv okio/pom.xml $out/okio-${version}.pom || true
  '';

  meta = with lib; {
    description = "okio_1_17_4 built from source";
    license = licenses.asl20;
    sourceProvenance = with sourceTypes; [ fromSource ];
  };
}
