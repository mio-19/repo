{
  fetchFromGitHub,
  jdk17_headless,
  lib,
  mkMavenPackageWithLock,
}:

mkMavenPackageWithLock rec {
  pname = "gson";
  version = "2.11.0";

  src = fetchFromGitHub {
    owner = "google";
    repo = "gson";
    tag = "gson-parent-${version}";
    hash = "sha256-HyQCgviEfzLjoxE0MbmbK0Ht52DWeWrq9P8ma/0kdSQ=";
  };

  sourceRoot = "${src.name}/gson";
  lockFile = ./mvn2nix-lock.json;

  mvnJdk = jdk17_headless;
  mvnFlags = [
    "-Dspotless.check.skip=true"
    "-Dmaven.javadoc.skip=true"
    "package"
  ];

  installPhase = ''
    runHook preInstall

    mkdir -p $out
    cp ${src}/pom.xml $out/gson-parent-${version}.pom
    cp target/gson-${version}.jar $out/
    cp pom.xml $out/gson-${version}.pom

    runHook postInstall
  '';

  meta = with lib; {
    description = "Java serialization and deserialization library for JSON";
    homepage = "https://github.com/google/gson";
    license = licenses.asl20;
  };
}
