# based on https://github.com/fzakaria/mvn2nix/blob/master/maven.nix
{
  lib,
  fetchurl,
  linkFarm,
  overrides-fromsrc,
}:
let
  inherit (lib) forEach attrValues;
  # "org/apache/maven/surefire/surefire-shared-utils/3.2.5/surefire-shared-utils-3.2.5.jar" -> "org.apache.maven.surefire:surefire-shared-utils:3.2.5"
  # "aopalliance/aopalliance/1.0/aopalliance-1.0.pom" -> "aopalliance:aopalliance:1.0"
  pathToCoords =
    path:
    let
      parts = builtins.filter builtins.isString (builtins.split "/" path);
      n = builtins.length parts;

      version = builtins.elemAt parts (n - 2);
      artifact = builtins.elemAt parts (n - 3);
      groupParts = lib.lists.sublist 0 (n - 3) parts;
      group = builtins.concatStringsSep "." groupParts;
    in
    "${group}:${artifact}:${version}";
  # "aopalliance/aopalliance/1.0/aopalliance-1.0.pom" -> "aopalliance-1.0.pom"
  fileName =
    path:
    let
      parts = builtins.filter builtins.isString (builtins.split "/" path);
      n = builtins.length parts;
    in
    builtins.elemAt parts (n - 1);
  overrideFromSrc =
    binary: layout:
    let
      group = pathToCoords layout;
      file = fileName layout;
      entry = (overrides-fromsrc."${group}" or { })."${file}" or (_: binary);
    in
    entry binary;
  # Create a maven environment from the output of the mvn2nix command
  # the resulting store path can be used as the a .m2 repository for subsequent
  # maven invocations.
  # ex.
  # 	mvn package --offline -Dmaven.repo.local=${repository}
  #
  # @param dependencies: A attrset of dependencies to build the repository
  buildMavenRepository =
    { dependencies }:
    let
      dependenciesAsDrv = (
        forEach (attrValues dependencies) (dependency: {
          drv = fetchurl {
            url = dependency.url;
            sha256 = dependency.sha256;
          };
          layout = dependency.layout;
        })
      );
    in
    linkFarm "mvn2nix-repository" (
      forEach dependenciesAsDrv (dependency: {
        name = dependency.layout;
        path = overrideFromSrc dependency.drv dependency.layout;
      })
    );

  # Create a maven environment from the output of the mvn2nix command
  # the resulting store path can be used as the a .m2 repository for subsequent
  # maven invocations.
  # ex.
  # 	mvn package --offline -Dmaven.repo.local=${repository}
  #
  # @param file: A path to a file containing the JSON output of running mvn2nix
  buildMavenRepositoryFromLockFile =
    { file }:
    let
      dependencies = (builtins.fromJSON (builtins.readFile file)).dependencies;
    in
    buildMavenRepository { inherit dependencies; };
in
buildMavenRepositoryFromLockFile
