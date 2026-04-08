{
  lib,
  maven,
  fetchFromGitHub,
}:

maven.buildMavenPackage rec {
  pname = "guava-android";
  version = "31.1";

  src = fetchFromGitHub {
    owner = "google";
    repo = "guava";
    rev = "v31.1";
    hash = "sha256-l4ZfHi8iO+Vz1zZGQxLjuPEA24AZ4kNHU0m3aFnhYWs=";
  };

  # We only want to build the android variant and ignore others to keep it minimal
  sourceRoot = "${src.name}/android";

  mvnHash = "sha256-jOVCO6RE1lNu4RV3T3F0v4sjje7WyYGFYc1whR6Kzmc=";

  mvnParameters = "-Dmaven.test.skip=true";

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
