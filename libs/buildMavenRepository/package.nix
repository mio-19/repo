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
    {
      dependencies,
      pathMap ? x: x,
    }:
    let
      dependenciesAsDrv = (
        forEach (attrValues dependencies) (dependency: {
          drv =
            if dependency ? package then
              dependency.package
            else
              fetchurl (
                {
                  url = dependency.url;
                }
                // lib.optionalAttrs (dependency ? sha256) {
                  sha256 = dependency.sha256;
                }
                // lib.optionalAttrs (dependency ? hash) {
                  hash = dependency.hash;
                }
              );
          layout = dependency.layout;
        })
      );
    in
    linkFarm "mvn2nix-repository" (
      forEach dependenciesAsDrv (dependency: {
        name = pathMap dependency.layout;
        path = overrideFromSrc dependency.drv dependency.layout;
      })
    );

in
buildMavenRepository
