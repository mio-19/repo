{
  callPackage,
  fetchFromGitHub,
  buildMavenRepositoryFromLockFile,
  buildMavenRepository,
  libsUtils,
}:
let
  maven_nixpkgs = callPackage ./nixpkgs.nix { };
  inherit (libsUtils) checkMavenProvides exposeMavenProvides;
  inherit (buildMavenRepositoryFromLockFile.passthru) mergeDeps fromGradleLock;
in
maven_nixpkgs.overrideAttrs (
  finalAttrs: prevAttrs: {
    version = "3.3.9";
    src = fetchFromGitHub {
      owner = "apache";
      repo = "maven";
      tag = "maven-${finalAttrs.version}";
      hash = "";
    };
    sourceRoot = finalAttrs.src.name;
    # https://maven.apache.org/guides/development/guide-building-maven.html
    buildPhase = ''
      runHook preBuild
      cp -r ${finalAttrs.mavenRepository} m2-repo
      chmod -R a+w m2-repo
      mvn -DdistributionTargetDir="out/apache-maven-${finalAttrs.version}" -Dmaven.repo.local=m2-repo -DskipITs -Dcpd.skip=true -Dpmd.skip=true -Dcheckstyle.skip=true -DskipTests -Dmaven.test.skip=true -Dspotless.apply.skip=true -Dspotless.check.skip=true -Drat.skip=true -Denforcer.skip=true install
    '';
    preInstall = ''
      find m2-repo -type l -delete
      for i in {1..10}; do find m2-repo -type d -empty -delete; done
      mv m2-repo apache-maven/out/apache-maven-${finalAttrs.version}/
      runHook postBuild
      cd apache-maven/out
    '';
    bootstrapMaven = maven_nixpkgs;
    nativeBuildInputs = prevAttrs.nativeBuildInputs ++ [ finalAttrs.bootstrapMaven ];
    mavenRepository = buildMavenRepository { dependencies = finalAttrs.passthru.mavenDependencies; };
    doInstallCheck = true;
    installCheckPhase = checkMavenProvides finalAttrs;
    passthru = prevAttrs.passthru // {
      # also run jq -S '.' on them.
      mavenDependencies = mergeDeps [
        # on darwin:
        # $ nix-shell -p jdk8
        # $ nix run github:mio-19/repo#mvn2nix > mvn2nix-lock.json
        ./mvn2nix-lock.json
      ];
      inherit maven_nixpkgs;
    };
    meta = prevAttrs.meta // {
      mavenProvides = exposeMavenProvides finalAttrs;
      # TODO
      mavenProvidesInternal = { };
    };
  }
)
