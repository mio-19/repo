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
      hash = "sha256-qqk0FyPo0X43d9Co7qe193D9lIj6DbJ7Tu7WGoD5QkY=";
    };
    sourceRoot = finalAttrs.src.name;
    # https://maven.apache.org/guides/development/guide-building-maven.html
    buildPhase = ''
      runHook preBuild
      cp -r ${finalAttrs.mavenRepository} m2-repo
      chmod -R a+w m2-repo
      mvn --offline -DdistributionTargetDir="out/apache-maven-${finalAttrs.version}" -Dmaven.repo.local=m2-repo -DskipITs -Dcpd.skip=true -Dpmd.skip=true -Dcheckstyle.skip=true -DskipTests -Dmaven.test.skip=true -Dspotless.apply.skip=true -Dspotless.check.skip=true -Drat.skip=true -Denforcer.skip=true install
    '';
    # After deleting symlinks, left are what it published.
    preInstall = ''
      find m2-repo -type l -delete
      for i in {1..10}; do find m2-repo -type d -empty -delete; done
      mv m2-repo apache-maven/out/apache-maven-${finalAttrs.version}/
      runHook postBuild
      cd apache-maven/out
    '';
    bootstrapMaven = maven_nixpkgs;
    nativeBuildInputs = prevAttrs.nativeBuildInputs ++ [ finalAttrs.bootstrapMaven ];
    mavenRepository = buildMavenRepository { dependencies = finalAttrs.passthru.mavenDeps; };
    doInstallCheck = true;
    installCheckPhase = checkMavenProvides finalAttrs;
    passthru = prevAttrs.passthru // {
      # also run jq -S '.' on them.
      mavenDeps = mergeDeps [
        # ../maven_3_9_14/refresh-hashes.sh merged-dependencies.json
        #./merged-dependencies.json
        ./linux-m2.json
        #./more.json
      ];
    };
    meta = prevAttrs.meta // {
      mavenProvides = exposeMavenProvides finalAttrs;
      # TODO
      mavenProvidesInternal = { };
    };
  }
)
