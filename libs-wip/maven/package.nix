{
  callPackage,
  fetchFromGitHub,
  buildMavenRepositoryFromLockFile,libsUtils,
}:
let
  maven_nixpkgs = callPackage ./nixpkgs.nix { };
  inherit (libsUtils) checkMavenProvides exposeMavenProvides;
in
maven_nixpkgs.overrideAttrs (
  finalAttrs: prevAttrs: {
    version = "3.9.14";
    src = fetchFromGitHub {
      owner = "apache";
      repo = "maven";
      tag = "maven-${finalAttrs.version}";
      hash = "";
    };
    # https://maven.apache.org/guides/development/guide-building-maven.html
    buildPhase = ''
      runHook preBuild
      mkdir out
      mvn -DdistributionTargetDir="out/apache-maven-${finalAttrs.version}" -Dmaven.repo.local=${finalAttrs.mavenRepository} install
      runHook postBuild
    '';
    preInstall = ''
      cd out
    '';
    bootstrapMaven = maven_nixpkgs;
    nativeBuildInputs = prevAttrs.nativeBuildInputs ++ [ finalAttrs.bootstrapMaven ];
    mavenRepository = buildMavenRepositoryFromLockFile { file = ./mvn2nix-lock.json; };
    doInstallCheck = true;
    installCheckPhase = ''
      ${checkMavenProvides finalAttrs}
    '';
    meta = prevAttrs.meta // {
      mavenProvides = exposeMavenProvides finalAttrs;
      mavenProvidesInternal = {};
    };
  }
)
