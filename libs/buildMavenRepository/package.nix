# based on https://github.com/fzakaria/mvn2nix/blob/master/maven.nix
{
  lib,
  fetchurl,
  linkFarm,
  overrides-fromsrc,
  buildMavenRepo,
  deepMerge,
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
      overrides ? overrides-fromsrc,
    }:
    let
      doOverrides =
        binary: layout:
        let
          group = pathToCoords layout;
          file = fileName layout;
          entry = (overrides."${group}" or { })."${file}" or (_: binary);
        in
        entry binary;
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
        path = doOverrides dependency.drv dependency.layout;
      })
    );
in
{
  __functor = _: buildMavenRepository;
  passthru = {
    fromGradleLock =
      let
        inherit (lib) mapAttrsToList;
        prefixes = [
          "https://repo.maven.apache.org/maven2/"
          "https://dl.google.com/dl/"
          "https://plugins.gradle.org/m2/"
          "https://jitpack.io/"
        ];
        stripPrefix =
          url: prefix:
          let
            prefixLen = builtins.stringLength prefix;
            urlLen = builtins.stringLength url;
          in
          if builtins.substring 0 prefixLen url == prefix then
            builtins.substring prefixLen (urlLen - prefixLen) url
          else
            null;
        urlToLayout =
          url:
          let
            matches = builtins.filter (x: x != null) (map (stripPrefix url) prefixes);
          in
          if matches != [ ] then
            builtins.head matches
          else
            throw "fromGradleLock: unexpected url prefix: ${url}";
      in
      lockFile:
      let
        lock = buildMavenRepo.passthru.readLockFile lockFile;
        doublelist = mapAttrsToList (
          gav: files:
          (mapAttrsToList (file: entry: {
            name = "${gav}:${file}";
            value = {
              layout = urlToLayout entry.url;
              hash = entry.hash;
              url = entry.url;
            };
          }) files)
        ) lock;
        flattened = lib.lists.flatten doublelist;
        dependencies = builtins.listToAttrs flattened;
      in
      dependencies;
  };
}
