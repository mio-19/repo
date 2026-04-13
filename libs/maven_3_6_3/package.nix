{
  maven_3_3_9,
  fetchFromGitHub,
  buildMavenRepositoryFromLockFile,
  jdk11_headless,
}:
let
  inherit (buildMavenRepositoryFromLockFile.passthru) mergeDeps fromGradleLock;
in
maven_3_3_9.overrideAttrs (
  finalAttrs: prevAttrs: {
    version = "3.6.3";
    src = fetchFromGitHub {
      owner = "apache";
      repo = "maven";
      tag = "maven-${finalAttrs.version}";
      hash = "sha256-A5icuvfRG0uLI0W5rXDwHwkryX8lyye2Cb+AFcM2+UY=";
    };
    bootstrapMaven = maven_3_3_9;
    jdk = jdk11_headless;
    passthru = prevAttrs.passthru // {
      # also run jq -S '.' on it.
      mavenDeps = mergeDeps [
        ./more.json
        ./linux-m2.json
      ];
    };
  }
)
