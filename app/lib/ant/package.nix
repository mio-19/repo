{
  fetchFromGitHub,
  jdk25_headless,
  jdk21_headless,
  lib,
  stdenv,
  callPackage,
  jdk8_headless,
  libsUtils,
}:
let
  postfix = if stdenv.isDarwin then "" else "/lib/openjdk";
  ant_nixpkgs = callPackage ./nixpkgs.nix { };
  inherit (libsUtils) checkMavenProvides exposeMavenProvides;
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
      mavenProvides = exposeMavenProvides finalAttrs;
      mavenProvidesInternal =
        let
          parent = {
            "org.apache.ant:ant-parent:${finalAttrs.version}" = {
              "ant-parent-${finalAttrs.version}.pom" = "${finalAttrs.src}/src/etc/poms/pom.xml";
            };
          };
          postfixes = [
            ""
            "-launcher"
          ]
          ++ lib.optionals (false && finalAttrs.version == "1.10.12") [
            "-juint"
          ]
          ++ lib.optionals (lib.strings.compareVersions finalAttrs.version "1.10.0" >= 0) [
            "-antlr"
          ];
          name = postfix: "org.apache.ant:ant${postfix}:${finalAttrs.version}";
          value = postfix: {
            "ant${postfix}-${finalAttrs.version}.jar" = "$out/share/ant/lib/ant${postfix}.jar";
            "ant${postfix}-${finalAttrs.version}.pom" = "${finalAttrs.src}/src/etc/poms/ant${postfix}/pom.xml";
          };
          child = builtins.listToAttrs (
            map (postfix: {
              name = name postfix;
              value = value postfix;
            }) postfixes
          );
        in
        parent // child;
    };
  }
)
