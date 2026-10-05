{
  lib,
  fetchgit,
  jdk11_headless,
  maven_3_9_14,
}:
let
  version = "4.1.110.Final";
  src = fetchgit {
    url = "https://github.com/netty/netty.git";
    rev = "netty-4.1.110.Final";
    hash = "sha256-M1Abm1CcotcHa7xtMZmhA5qCpGLn4X/DKNHBbJSuw1Y=";
  };
in
maven_3_9_14.buildMavenPackage {
  pname = "netty";
  inherit version src;
  mvnJdk = jdk11_headless;

  mvnHash = "sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=";
  mvnParameters = "-DskipTests -Dmaven.javadoc.skip=true -Dcheckstyle.skip=true";

  installPhase = ''
    mkdir -p $out
    for module in common buffer codec codec-http codec-http2 codec-socks handler handler-proxy resolver transport transport-native-unix-common; do
      mv $module/target/netty-$module-${version}.jar $out/netty-$module-${version}.jar || true
      mv $module/pom.xml $out/netty-$module-${version}.pom || true
    done
    mv pom.xml $out/netty-parent-${version}.pom || true
  '';

  meta = with lib; {
    description = "netty_4_1_110 built from source";
    license = licenses.mit;
    sourceProvenance = with sourceTypes; [ fromSource ];
  };
}
