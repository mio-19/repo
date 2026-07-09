{
  groovy_1_8_9,
  fetchFromGitHub,
  buildMavenRepositoryFromLockFile,
}:
let
  inherit (buildMavenRepositoryFromLockFile.passthru) mergeDeps readDeps;
in
groovy_1_8_9.overrideAttrs (
  finalAttrs: prevAttrs: {
    version = "1.6.4";
    src = fetchFromGitHub {
      owner = "apache";
      repo = "groovy";
      tag = "GROOVY_1_6_4";
      hash = "sha256-3W/D6sp/1thclr0jp+W/7V3T5au3VbbL6DPW5X2h89g=";
    };
    passthru = prevAttrs.passthru // {
      mavenDeps = mergeDeps [
        ./more.json
        groovy_1_8_9.passthru.mavenDeps
      ];
    };
  }
)
