{
  fetchFromGitHub,
  jdk25_headless,
  jdk21_headless,
  lib,
  stdenv,
  callPackage,
  jdk8_headless,
  checkMavenProvides,
}:
let
  postfix = if stdenv.isDarwin then "" else "/lib/openjdk";
  ant_nixpkgs = callPackage ./nixpkgs.nix { };
in
ant_nixpkgs.overrideAttrs (
  finalAttrs: prevAttrs:
  let
    jdk =
      if lib.strings.compareVersions finalAttrs.version "1.10.14" >= 0 then
        jdk25_headless
      else if lib.strings.compareVersions finalAttrs.version "1.10.0" >= 0 then
        jdk21_headless
      else
        jdk8_headless;
  in
  {
    version = "1.10.15";
    nativeBuildInputs = [ jdk ];
    src = fetchFromGitHub {
      owner = "apache";
      repo = "ant";
      tag = "rel/${finalAttrs.version}";
      hash = "sha256-lRaDj8MMfuMqjXwHglZlKgqUmkbbs0dCTDFF61zW5Qg=";
    };
    # https://ant.apache.org/manual/install.html#buildingant Since Ant 1.7.0, Ant has a hard dependency on JUnit.
    postPatch =
      lib.optionalString (lib.strings.compareVersions finalAttrs.version "1.7.0" < 0) ''
        find . -name "*.jar" -print0 | xargs -0 rm
        echo "Removed all .jar files"
      ''
      + lib.optionalString (finalAttrs.version == "1.7.0") ''
        rm src/tests/junit/org/apache/tools/ant/taskdefs/SQLExecTest.java
      '';
    preBuild = lib.optionalString (lib.strings.compareVersions finalAttrs.version "1.9.6" <= 0) ''
      export CLASSPATH=${jdk}${postfix}/lib/tools.jar
    '';
    buildPhase = ''
      runHook preBuild

      sh ./build.sh dist-lite
      mkdir out
      ANT_HOME=./out sh build.sh install-lite

      runHook postBuild
      cd out # for installPhase
    '';
    doInstallCheck = true;
    installCheckPhase = ''
      ${checkMavenProvides finalAttrs}
    '';
    meta = prevAttrs.meta // {
      mavenProvides = {
        "org.apache.ant:ant:${finalAttrs.version}" = {
          "ant-${finalAttrs.version}.jar" = _: "${placeholder "out"}/share/ant/lib/ant.jar";
          "ant-${finalAttrs.version}.pom" = _: "${finalAttrs.src}/src/etc/poms/ant/pom.xml";
        };
      };
    };
  }
)
