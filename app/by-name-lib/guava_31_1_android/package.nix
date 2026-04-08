{
  fetchFromGitHub,
  lib,
  mkMavenPackageWithLock,
}:

mkMavenPackageWithLock rec {
  pname = "guava-android";
  version = "31.1";

  src = fetchFromGitHub {
    owner = "google";
    repo = "guava";
    tag = "v31.1";
    hash = "sha256-l4ZfHi8iO+Vz1zZGQxLjuPEA24AZ4kNHU0m3aFnhYWs=";
  };

  # We only want to build the android variant and ignore others to keep it minimal
  sourceRoot = "${src.name}/android";
  lockFile = ./mvn2nix-lock.json;
  patches = [ ./pin-maven-plugin-versions.patch ];

  mvnFlags = [
    "-Dmaven.test.skip=true"
    "package"
  ];

  installPhase = ''
    runHook preInstall

    mkdir -p $out
    cp ${src}/android/pom.xml $out/guava-parent-${version}-android.pom
    cp guava/target/guava-31.1-android.jar $out/
    cp guava/pom.xml $out/guava-31.1-android.pom

    runHook postInstall
  '';

  meta = with lib; {
    description = "Google Core Libraries for Java";
    homepage = "https://github.com/google/guava";
    license = licenses.asl20;
  };
}
