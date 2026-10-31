{
  lib,
  fetchgit,
  maven_3_9_14,
}:
let
  version = "2.3.0";
  src = fetchgit {
    url = "https://github.com/stefanhaustein/kxml2.git";
    rev = "v2.3.0";
    hash = "sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=";
  };
in
maven_3_9_14.buildMavenPackage {
  pname = "kxml2";
  inherit version src;

  mvnHash = "sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=";
  mvnParameters = "-DskipTests -Dmaven.javadoc.skip=true";

  installPhase = ''
    mkdir -p $out
    mv target/kxml2-${version}.jar $out/kxml2-${version}.jar
    mv pom.xml $out/kxml2-${version}.pom
  '';

  meta = with lib; {
    description = "kxml2_2_3_0 built from source";
    license = licenses.mit;
    sourceProvenance = with sourceTypes; [ fromSource ];
  };
}
