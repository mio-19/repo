{
  lib,
  fetchgit,
  maven_3_9_14,
}:
let
  version = "3.9.0";
  src = fetchgit {
    url = "https://github.com/apache/commons-net.git";
    rev = "rel/commons-net-3.9.0";
    hash = "sha256-T8/y1QVu2LQRe3M3Z6ngUesbHJpIxbJFV2XmtmfdCJI=";
  };
in
maven_3_9_14.buildMavenPackage {
  pname = "commons-net";
  inherit version src;

  mvnHash = "sha256-RUNTBeupXhlkd6kBmfbdeP+xJn1Lhr6E0ApFjlTYBY8=";

  mvnParameters = "-DskipTests -Dmaven.javadoc.skip=true";

  installPhase = ''
    mkdir -p $out
    mv target/commons-net-3.9.0.jar $out/commons-net-3.9.0.jar
    mv pom.xml $out/commons-net-3.9.0.pom

  '';

  meta = with lib; {
    description = "commons_net_3_9_0 built from source";
    license = licenses.mit;
    sourceProvenance = with sourceTypes; [ fromSource ];
  };
}
