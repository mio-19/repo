{
  lib,
  fetchgit,
  jdk25_headless,
  maven_3_9_14,
}:
let
  version = "1.27.1";
  src = fetchgit {
    url = "https://github.com/apache/commons-compress.git";
    rev = "rel/commons-compress-1.27.1";
    hash = "sha256-4y8wYI9Z7U0yR1f4U2/9X9gY6GzV9W2Q0xM9v3X8wM8="; 
  };
in
maven_3_9_14.buildMavenPackage {
  pname = "commons-compress";
  inherit version src;

  mvnHash = "sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=";
  mvnParameters = "-DskipTests -Dmaven.javadoc.skip=true";

  installPhase = ''
    mkdir -p $out
    mv target/commons-compress-${version}.jar $out/commons-compress-${version}.jar
    mv pom.xml $out/commons-compress-${version}.pom
  '';

  meta = with lib; {
    description = "commons_compress_1_27_1 built from source";
    license = licenses.mit;
    sourceProvenance = with sourceTypes; [ fromSource ];
  };
}
