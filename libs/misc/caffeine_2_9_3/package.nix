{
  lib,
  fetchgit,
  jdk11_headless,
  maven_3_9_14,
}:
let
  version = "2.9.3";
  src = fetchgit {
    url = "https://github.com/ben-manes/caffeine.git";
    rev = "v2.9.3";
    hash = "sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=";
  };
in
maven_3_9_14.buildMavenPackage {
  pname = "caffeine";
  inherit version src;
  mvnJdk = jdk11_headless;

  mvnHash = "sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=";
  mvnParameters = "-DskipTests -Dmaven.javadoc.skip=true";

  installPhase = ''
    mkdir -p $out
    mv caffeine/build/libs/caffeine-${version}.jar $out/caffeine-${version}.jar || true
    mv caffeine/build/publications/maven/pom-default.xml $out/caffeine-${version}.pom || true
  '';

  meta = with lib; {
    description = "caffeine_2_9_3 built from source";
    license = licenses.mit;
    sourceProvenance = with sourceTypes; [ fromSource ];
  };
}
