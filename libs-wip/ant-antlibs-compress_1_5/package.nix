{
  ant,
  fetchFromGitHub,
  stdenv,
  lib,
  libsUtils,
  jdk21_headless,
  buildMavenRepositoryFromLockFile,
}:
let
  m2Repo = buildMavenRepositoryFromLockFile {
    file = ./mvn.json;
  };
in
stdenv.mkDerivation (finalAttrs: {
  pname = "ant-antlibs-compress";
  version = "1.5";

  src = fetchFromGitHub {
    owner = "apache";
    repo = "ant-antlibs-compress";
    tag = "rel/${finalAttrs.version}";
    hash = "sha256-HofFCrSe0eqgOa9EetrJehfafWstjnfh8M4DBrvK+eY=";
    fetchSubmodules = true;
  };
  nativeBuildInputs = [
    ant
    jdk21_headless
  ];
  postPatch = ''
    sed -i 's|<target name="download-ivy"|<target name="download-ivy" unless="offline"|' common/ivy.xml
  '';
  buildPhase = ''
    runHook preBuild

    mkdir ivy
    cp ${m2Repo}/org/apache/ivy/ivy/2.4.0/ivy-2.4.0.jar ivy/ivy.jar

    mkdir out
    ANT_HOME=./out ant -Doffline=true install

    runHook postBuild
    cd out # for installPhase
  '';

  installPhase = ''
    false
  '';

  meta = with lib; {
    description = "Apache Ant's Compress library";
    homepage = "https://projects.apache.org/project.html?ant-compress";
    license = licenses.asl20;
    platforms = platforms.unix;
    broken = true;
  };
})
