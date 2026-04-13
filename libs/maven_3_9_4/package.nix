{
  maven_3_9_14,
  fetchFromGitHub,
  buildMavenRepositoryFromLockFile,
  jdk11_headless,
}:
let
  inherit (buildMavenRepositoryFromLockFile.passthru) mergeDeps;
in
maven_3_9_14.overrideAttrs (
  finalAttrs: prevAttrs: {
    version = "3.9.4";
    src = fetchFromGitHub {
      owner = "apache";
      repo = "maven";
      tag = "maven-${finalAttrs.version}";
      hash = "sha256-uMRQGDE/LfTM50Dc2b08OBoeIkS8gcA3xWlSpSQs7Rc=";
    };
    bootstrapMaven = maven_3_9_14;
    jdk = jdk11_headless;
    passthru = prevAttrs.passthru // {
      # also run jq -S '.' on it.
      mavenDeps = mergeDeps [
        ./linux-m2.json
        ./more.json
        ../maven_3_9_14/mvn2nix-lock.json
      ];
    };
  }
)
