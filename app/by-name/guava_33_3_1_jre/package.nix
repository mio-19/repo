{
  lib,
  maven,
  fetchFromGitHub,
}:

maven.buildMavenPackage rec {
  pname = "guava-jre";
  version = "33.3.1";

  src = fetchFromGitHub {
    owner = "google";
    repo = "guava";
    rev = "v33.3.1";
    hash = "sha256-SnZ7+lft8r/VXzaY+jGb4SWhJyeEm4uW+s6V6r8qI6M=";
  };

  patches = [ ./disable-toolchain-download.patch ];

  mvnHash = "sha256-HRbcNpA0aGk78l2sWGxDrM6k0KQe+XIiWgX5kt5J/tg=";

  mvnParameters = "-pl guava -am -Dmaven.javadoc.skip=true -Dmaven.source.skip=true package";

  installPhase = ''
    runHook preInstall

    mkdir -p "$out"
    cp pom.xml "$out/guava-parent-33.3.1-jre.pom"
    cp guava/target/guava-33.3.1-jre.jar "$out/"
    cp guava/pom.xml "$out/guava-33.3.1-jre.pom"
    cp guava/target/publish/module.json "$out/guava-33.3.1-jre.module"

    runHook postInstall
  '';

  meta = with lib; {
    description = "Google Core Libraries for Java";
    homepage = "https://github.com/google/guava";
    license = licenses.asl20;
  };
}
