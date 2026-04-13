{
  callPackage,
  fetchFromGitHub,
  buildMavenRepositoryFromLockFile,
  buildMavenRepository,
  libsUtils,
  jdk8_headless,
  lib,
  maven_3_3_9_ant,
}:
let
  maven_nixpkgs = callPackage ./nixpkgs.nix { };
  inherit (libsUtils) checkMavenProvides exposeMavenProvides;
  inherit (buildMavenRepositoryFromLockFile.passthru) mergeDeps readDeps;
in
maven_nixpkgs.overrideAttrs (
  finalAttrs: prevAttrs:
  let
    useDistributionTargetDir = lib.strings.compareVersions finalAttrs.version "3.3.9" > 0;
    extraFlags =
      lib.optionals (lib.strings.compareVersions finalAttrs.version "3.3.9" <= 0) [
        "-Dremoteresources.skip=true"
      ]
      ++ lib.optionals useDistributionTargetDir [
        ''-DdistributionTargetDir="out/apache-maven-${finalAttrs.version}"''
      ];
  in
  {
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
      mvn --offline -Dmaven.repo.local=m2-repo -DskipITs -Dcpd.skip=true -Dpmd.skip=true -Dcheckstyle.skip=true -DskipTests -Dmaven.test.skip=true -Dspotless.apply.skip=true -Dspotless.skip=true -Dspotless.check.skip=true -Dmaven.javadoc.skip=true -Drat.skip=true -Denforcer.skip=true ${builtins.concatStringsSep " " extraFlags} install
      runHook postBuild
    '';
    preInstall =
      lib.optionalString (!useDistributionTargetDir) ''
        mkdir apache-maven/out
        cd apache-maven/out
        tar -xzf ../target/apache-maven-${finalAttrs.version}-bin.tar.gz
        cd ../..
      ''
      # After deleting symlinks, left are what it published.
      + ''
        find m2-repo -type l -delete
        for i in {1..10}; do find m2-repo -type d -empty -delete; done
        mv m2-repo apache-maven/out/apache-maven-${finalAttrs.version}/
        cd apache-maven/out
      '';
    bootstrapMaven = maven_3_3_9_ant;
    jdk = jdk8_headless;
    nativeBuildInputs = prevAttrs.nativeBuildInputs ++ [
      finalAttrs.bootstrapMaven
      finalAttrs.jdk
    ];
    mavenRepository = buildMavenRepository { dependencies = readDeps finalAttrs.passthru.mavenDeps; };
    doInstallCheck = true;
    installCheckPhase = checkMavenProvides finalAttrs;
    passthru = prevAttrs.passthru // {
      # also run jq -S '.' on it.
      # also need to manually remove 3.3.9 entries from linux-m2.json
      # jq '.dependencies |= with_entries(select(.key | test("^org\\.apache\\.maven[^:]*:[^:]+:[^:]+:3\\.3\\.9(:[^:]+)?$") | not))' linux-m2.json > tmp && mv tmp linux-m2.json
      mavenDeps = ./linux-m2.json;
    };
    meta = prevAttrs.meta // {
      mavenProvides = exposeMavenProvides finalAttrs;
      # nix-repl> legacyPackages.x86_64-linux.overrides-fromsrc-bare."org.apache.maven:maven-model-builder:3.9.14"."maven-model-builder-3.9.14.jar" null
      mavenProvidesInternal =
        let
          postfixes = [
            ""
            "-artifact"
            "-builder-support"
            "-compat"
            "-core"
            "-model"
            "-model-builder"
            "-plugin-api"
          ]
          ++ lib.optionals (lib.strings.compareVersions finalAttrs.version "3.6.3" >= 0) [
          ];
          name = postfix: "org.apache.maven:maven${postfix}:${finalAttrs.version}";
          value =
            postfix:
            {
              "maven${postfix}-${finalAttrs.version}.pom" =
                "$out/maven/m2-repo/org/apache/maven/maven${postfix}/${finalAttrs.version}/maven${postfix}-${finalAttrs.version}.pom";
            }
            // lib.optionalAttrs (postfix != "") {
              "maven${postfix}-${finalAttrs.version}.jar" =
                "$out/maven/m2-repo/org/apache/maven/maven${postfix}/${finalAttrs.version}/maven${postfix}-${finalAttrs.version}.jar";
            };
          children = builtins.listToAttrs (
            map (postfix: {
              name = name postfix;
              value = value postfix;
            }) postfixes
          );
        in
        children;
    };
  }
)
