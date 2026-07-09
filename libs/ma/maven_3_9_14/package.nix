{
  maven_3_6_3,
  fetchFromGitHub,
  buildMavenRepositoryFromLockFile,
  jdk11_headless,
}:
let
  inherit (buildMavenRepositoryFromLockFile.passthru) mergeDeps;
in
maven_3_6_3.overrideAttrs (
  finalAttrs: prevAttrs: {
    version = "3.9.14";
    src = fetchFromGitHub {
      owner = "apache";
      repo = "maven";
      tag = "maven-${finalAttrs.version}";
      hash = "sha256-fCqLWXxCznnD8bzHHaBWD7r0yb3mKu+5ApxpqYP42tg=";
    };
    bootstrapMaven = maven_3_6_3;
    jdk = jdk11_headless;
    passthru = prevAttrs.passthru // {
      # also run jq -S '.' on them.
      # Derived from the artifacts Maven actually populated into .m2 while
      # building 3.9.14. This keeps the lock focused on the real offline build
      # closure instead of layering heuristic extras from synthetic lock files.
      mavenDeps = mergeDeps [
        ./linux-m2.json
        ./more.json
      ];
    };
  }
)
