{
  lib,
  fetchgit,
  jdk11_headless,
  maven_3_9_14,
}:
let
  version = "3.6.1";
  src = fetchgit {
    url = "https://github.com/apache/commons-math.git";
    rev = "MATH_3_6_1";
    hash = "sha256-NslPIw9kksS4AeHQ5PlOhHiBivj0gQO/voZz0/kIycw=";
  };
in
maven_3_9_14.buildMavenPackage {
  pname = "commons-math3";
  inherit version src;
  mvnJdk = jdk11_headless;

  mvnHash = "sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=";

  postPatch = ''
    substituteInPlace pom.xml \
      --replace-fail "<maven.compiler.source>1.5</maven.compiler.source>" "<maven.compiler.source>8</maven.compiler.source>" \
      --replace-fail "<maven.compiler.target>1.5</maven.compiler.target>" "<maven.compiler.target>8</maven.compiler.target>"
  '';

  mvnParameters = "-DskipTests -Dmaven.javadoc.skip=true";

  installPhase = ''
    mkdir -p $out
    mv target/commons-math3-${version}.jar $out/commons-math3-${version}.jar
    mv pom.xml $out/commons-math3-${version}.pom
  '';

  meta = with lib; {
    description = "commons_math3_3_6_1 built from source";
    license = licenses.mit;
    sourceProvenance = with sourceTypes; [ fromSource ];
  };
}
