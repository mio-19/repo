{
  callPackage,
  fetchFromGitHub,
  buildMavenRepositoryFromLockFile,
  buildMavenRepository,
  libsUtils,
  jdk8_headless,
  lib,
  stdenv,
  ant,
}:
let
  maven_nixpkgs = callPackage ../maven_3_3_9_mvn/nixpkgs.nix { };
  inherit (libsUtils) checkMavenProvides exposeMavenProvides;
  inherit (buildMavenRepositoryFromLockFile.passthru) mergeDeps readDeps;

  postfix = if stdenv.isDarwin then "" else "/lib/openjdk";
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
    postPatch = ''
      substituteInPlace build.xml --replace-fail '<arg value="-DskipTests=''${skipTests}" />' '<arg value="-DskipTests=''${skipTests}" /><arg value="-Drat.skip=true" /><arg value="-Denforcer.skip=true" /><arg value="-Dremoteresources.skip=true" />'
      substituteInPlace build.xml \
      --replace-fail '<java fork="''${maven-compile.fork}" classname="org.apache.maven.cli.MavenCli" failonerror="true" timeout="600000"  maxmemory="''${maven-compile.maxmemory}">' \
                     '<java fork="''${maven-compile.fork}" jvm="${finalAttrs.env.JAVA_HOME}/bin/java" classname="org.apache.maven.cli.MavenCli" failonerror="true" timeout="600000"  maxmemory="''${maven-compile.maxmemory}">'
    '';
    # https://github.com/apache/maven/tree/maven-3.3.9
    buildPhase = ''
      runHook preBuild
      mkdir out
      cp -r ${finalAttrs.mavenRepository} m2-repo
      chmod -R a+w m2-repo
      ant -Dmaven.repo.local=m2-repo -Dmaven.home="$PWD/out/apache-maven-${finalAttrs.version}" -DskipTests=true -Dmaven.test.skip=true
      runHook postBuild
    '';
    preInstall = ''
      find m2-repo -type l -delete
      for i in {1..10}; do find m2-repo -type d -empty -delete; done
      mv m2-repo out/apache-maven-${finalAttrs.version}/
      cd out
    '';
    jdk = jdk8_headless;
    nativeBuildInputs = prevAttrs.nativeBuildInputs ++ [
      finalAttrs.jdk
      ant
    ];
    env = {
      JAVA_HOME = finalAttrs.jdk + postfix;
    };
    mavenRepository = buildMavenRepository { dependencies = readDeps finalAttrs.passthru.mavenDeps; };
    passthru = prevAttrs.passthru // {
      mavenDeps = mergeDeps [
        ./more.json
        ../maven_3_3_9_mvn/linux-m2.json
      ];
    };
  }
)
