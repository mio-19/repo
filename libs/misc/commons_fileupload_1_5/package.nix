{
  lib,
  fetchgit,
  maven_3_9_14,
}:
let
  version = "1.5";
  src = fetchgit {
    url = "https://github.com/apache/commons-fileupload.git";
    rev = "commons-fileupload-1.5";
    hash = "sha256-tMxmgcjALb3yEN4Dawuvpn3o0u4/tOTsEvIM3NZ/Dxg=";
  };
in
maven_3_9_14.buildMavenPackage {
  pname = "commons-fileupload";
  inherit version src;
  
  mvnHash = "sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=";
  
  mvnParameters = "-DskipTests -Dmaven.javadoc.skip=true";
  
  installPhase = ''
    mkdir -p $out
    mv target/commons-fileupload-1.5.jar $out/commons-fileupload-1.5.jar
    mv pom.xml $out/commons-fileupload-1.5.pom

  '';

  meta = with lib; {
    description = "commons_fileupload_1_5 built from source";
    license = licenses.mit;
    sourceProvenance = with sourceTypes; [ fromSource ];
  };
}
