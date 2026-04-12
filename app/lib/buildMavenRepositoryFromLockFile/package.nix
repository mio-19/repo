# based on https://github.com/fzakaria/mvn2nix/blob/master/maven.nix
{ buildMavenRepository }:
let
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
