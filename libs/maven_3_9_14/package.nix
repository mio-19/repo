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
    version = "3.9.14";
    src = fetchFromGitHub {
      owner = "apache";
      repo = "maven";
      tag = "maven-${finalAttrs.version}";
      hash = "sha256-fCqLWXxCznnD8bzHHaBWD7r0yb3mKu+5ApxpqYP42tg=";
    };
    sourceRoot = finalAttrs.src.name;
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
    mavenRepository = buildMavenRepository { dependencies = finalAttrs.passthru.mavenDependencies; };
    doInstallCheck = true;
    installCheckPhase = ''
      ${checkMavenProvides finalAttrs}
    '';
    passthru = prevAttrs.passthru // {
      mavenDependencies = mergeDeps [
        # on darwin $ nix run github:mio-19/repo#mvn2nix -- --goals install > mvn2nix-lock.json ; manual edit to remove apache-maven-3.9.14 maven-artifact-3.9.14 and other maven*-3.9.14
        # on darwin $ nix run github:mio-19/repo#mvn2nix -- --goals dependency:resolve > mvn2nix-lock-resolve.json  # merge with jq -s 'reduce .[] as $item ({}; . * $item)'
        # on darwin cd apache-maven && nix run github:mio-19/repo#mvn2nix > mvn2nix-lock.json
        ./mvn2nix-lock.json
        # com/diffplug/spotless/spotless-maven-plugin/3.1.0/spotless-maven-plugin-3.1.0.pom  maven/plugins/maven-install-plugin/3.1.4/maven-install-plugin-3.1.4.pom
        ./messy.json
        # kotlin-stdlib-jdk8-1.9.10.pom org/eclipse/platform/org.eclipse.osgi/3.18.300 com/diffplug/spotless/spotless-lib/4.1.0/spotless-lib-4.1.0.pom com/diffplug/durian/durian-core/1.2.0/durian-core-1.2.0.pom org.eclipse.jgit:org.eclipse.jgit:7.4.0.202509020913-r kotlin-stdlib-1.8.21.pom and more
        # also see README.md
        (fromGradleLock ./messy.lock)
        ./more.json
        (fromGradleLock ./more.lock)
        # git clone https://github.com/diffplug/spotless.git && cd spotless && nix run github:mio-19/repo#gradle2nix
        #(fromGradleLock ./spotless.lock)
      ];
    };
    meta = prevAttrs.meta // {
      mavenProvides = exposeMavenProvides finalAttrs;
      mavenProvidesInternal = { };
    };
  }
)
