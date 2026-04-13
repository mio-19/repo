{
  callPackage,
  fetchFromGitHub,
  buildMavenRepositoryFromLockFile,
  buildMavenRepository,
  libsUtils,
  jdk8_headless,
  lib,
  ant,
}:
let
  maven_nixpkgs = callPackage ../maven_3_3_9_mvn/nixpkgs.nix { };
  inherit (libsUtils) checkMavenProvides exposeMavenProvides;
  inherit (buildMavenRepositoryFromLockFile.passthru) mergeDeps readDeps;
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
    # https://github.com/apache/maven/tree/maven-3.3.9
    buildPhase = ''
      runHook preBuild
      mkdir out
      ant -Dmaven.repo.local=${finalAttrs.mavenRepository} -Dmaven.home="$PWD/out/apache-maven-${finalAttrs.version}"
      runHook postBuild
    '';
    preInstall = ''
      cd out
    '';
    jdk = jdk8_headless;
    nativeBuildInputs = prevAttrs.nativeBuildInputs ++ [
      finalAttrs.jdk
      ant
    ];
    mavenRepository = buildMavenRepository { dependencies = readDeps finalAttrs.passthru.mavenDeps; };
    passthru = prevAttrs.passthru // {
      mavenDeps = mergeDeps [
        ./more.json
        ../maven_3_3_9_mvn/linux-m2.json
      ];
    };
  }
)
