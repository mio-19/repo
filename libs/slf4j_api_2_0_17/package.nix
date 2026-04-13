{
  fetchFromGitHub,
  lib,
  mkMavenPackageWithLock,
  maven_nixpkgs,
}:

mkMavenPackageWithLock rec {
  maven = maven_nixpkgs;
  pname = "slf4j-api";
  version = "2.0.17";

  src = fetchFromGitHub {
    owner = "qos-ch";
    repo = "slf4j";
    tag = "v_${version}";
    hash = "sha256-MOAIvzVPxFv9Nfov4Ych774urZ0v9emscKqwIGI/3Ik=";
  };

  lockFile = ./mvn2nix-lock.json;
  mvnFlags = [
    "-pl"
    "slf4j-api"
    "-am"
    "-Dmaven.javadoc.skip=true"
    "package"
  ];

  installPhase = ''
    runHook preInstall

    mkdir -p "$out"
    cp pom.xml "$out/slf4j-bom-${version}.pom"
    cp parent/pom.xml "$out/slf4j-parent-${version}.pom"
    cp slf4j-api/target/slf4j-api-${version}.jar "$out/"
    cp slf4j-api/pom.xml "$out/slf4j-api-${version}.pom"

    runHook postInstall
  '';

  meta = with lib; {
    description = "Simple Logging Facade for Java API";
    homepage = "https://github.com/qos-ch/slf4j";
    license = licenses.mit;
  };
}
