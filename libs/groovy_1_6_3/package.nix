{
  groovy_1_6_4,
  fetchFromGitHub,
  buildMavenRepositoryFromLockFile,
}:
let
  inherit (buildMavenRepositoryFromLockFile.passthru) mergeDeps readDeps;
in
groovy_1_6_4.overrideAttrs (
  finalAttrs: prevAttrs: {
    version = "1.6.3";
    src = fetchFromGitHub {
      owner = "apache";
      repo = "groovy";
      tag = "GROOVY_1_6_3";
      hash = "sha256-5Z9wYZ9GnJIozhxkf36y+QPYv/+0YeUqaUK2VhmzT5c=";
    };
    postPatch = prevAttrs.postPatch + ''
      substituteInPlace  config/maven/groovy-tools.pom --replace-fail '0.0.258' '0.0.323'
    '';
    passthru = prevAttrs.passthru // {
      mavenDeps = mergeDeps [
        ./more.json
        groovy_1_6_4.passthru.mavenDeps
      ];
    };
  }
)
