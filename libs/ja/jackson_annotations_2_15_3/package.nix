{
  lib,
  fetchgit,
  maven_3_9_14,
  jdk11_headless,
}:
let
  version = "2.15.3";
  src = fetchgit {
    url = "https://github.com/FasterXML/jackson-annotations.git";
    rev = "jackson-annotations-2.15.3";
    hash = "sha256-0gkcJWxQNuj+vAerE30Fde+UqtTZuQejC/IBO/3fwck=";
  };
in
maven_3_9_14.buildMavenPackage {
  pname = "jackson-annotations";
  inherit version src;
  mvnJdk = jdk11_headless;

  mvnHash = "sha256-YYqjYGCHyc/QJDE9iTIGf+8AJJlGP5qDPsC2GvNMhz4=";

  mvnParameters = "-DskipTests -Dmaven.javadoc.skip=true -Dmaven.compiler.source=8 -Dmaven.compiler.target=8";

  installPhase = ''
    mkdir -p $out
    mv target/jackson-annotations-2.15.3.jar $out/jackson-annotations-2.15.3.jar
    mv pom.xml $out/jackson-annotations-2.15.3.pom

  '';

  meta = with lib; {
    description = "jackson_annotations_2_15_3 built from source";
    license = licenses.mit;
    sourceProvenance = with sourceTypes; [ fromSource ];
  };
}
