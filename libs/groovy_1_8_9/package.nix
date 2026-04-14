{
  callPackage,
  fetchFromGitHub,
  buildMavenRepositoryFromLockFile,
  buildMavenRepository,
  jdk8_headless,
  ant,
  stdenv,
  writableTmpDirAsHomeHook,
  fetchurl,
  runCommand,
  libsUtils,
}:
let
  inherit (buildMavenRepositoryFromLockFile.passthru) mergeDeps readDeps;
  bnd_384 = fetchurl {
    url = "https://repo1.maven.org/maven2/biz/aQute/bnd/0.0.384/bnd-0.0.384.pom";
    hash = "sha256-K1Q7NMOlTdxinjZ62KGVNRyGeBI2oB8rY1d45chT8Jo=";
  };
  bnd_401 = runCommand "bnd-0.0.401.pom" { } ''
    substitute ${bnd_384} $out --replace-fail '0.0.384' '0.0.401'
  '';
  inherit (libsUtils) checkMavenProvides exposeMavenProvides;
in
stdenv.mkDerivation (finalAttrs: {
  pname = "groovy";
  version = "1.8.9";
  src = fetchFromGitHub {
    owner = "apache";
    repo = "groovy";
    tag = "GROOVY_1_8_9";
    hash = "sha256-pG9jsyMEUMVoeqnI04Tk5g0Y5VRxBcTxVSw4HyGqF0E=";
  };
  sourceRoot = finalAttrs.src.name;
  postPatch =
    let
      targetP = ''<property name="targetDirectory" value="target"/>'';
      deps = ''<artifact:dependencies useScope="@{scope}" filesetId="fs.@{scope}.@{module}" pomRefId="@{module}.pom"'';
      pom = ''<artifact:pom file="@{file}" id="@{id}"'';
    in
    ''
      substituteInPlace config/ant/build-maven.xml \
        --replace-fail '${deps}/>' \
          '${deps}><localRepository path="''${maven.repo.local}" /></artifact:dependencies>' \
        --replace-fail '${pom}/>' \
          '${pom}><localRepository path="''${maven.repo.local}" /></artifact:pom>'
      substituteInPlace config/ant/build-setup.xml \
        --replace-fail '${targetP}' '${targetP}<property name="maven.repo.local" value="''${user.home}/.m2/repository" />'
      substituteInPlace build.xml \
        --replace-fail '<contains string="''${ant.version}" substring="1.1"></contains>' ""
      # cannot use substituteInPlace : substituteInPlace doesn't have \b
      sed -i 's|\bParameter\b|org.codehaus.groovy.ast.Parameter|g' src/main/org/codehaus/groovy/vmplugin/v5/Java5.java
    '';
  buildPhase = ''
    runHook preBuild
    ${ant}/bin/ant \
      -lib ${finalAttrs.mavenRepository}/antlr/antlr/2.7.6/antlr-2.7.6.jar \
      -Dmaven.repo.local=${finalAttrs.mavenRepository} \
      install -DskipTests=true -DskipOsgi=true
    runHook postBuild
  '';
  nativeBuildInputs = [
    ant
    jdk8_headless
  ];
  installPhase = ''
    runHook preInstall
    mv target/install $out
    mv target/dist/groovy-all-${finalAttrs.version}.jar $out/
    mv target/groovy-all.pom $out/groovy-all-${finalAttrs.version}.pom

    runHook postInstall
  '';
  mavenRepository = buildMavenRepository { dependencies = readDeps finalAttrs.passthru.mavenDeps; };
  doInstallCheck = true;
  installCheckPhase = checkMavenProvides finalAttrs;
  passthru = {
    mavenDeps = mergeDeps [
      ./more.json
      # remove biz.aQute:bnd:jar:0.0.401 biz.aQute:bnd:pom:0.0.401
      ./linux-m2.json
      # commons-collections:commons-collections:jar:2.1
      ../maven_3_3_9/linux-m2.json
      {
        "biz.aQute:bnd:pom:0.0.401" = {
          "layout" = "biz/aQute/bnd/0.0.401/bnd-0.0.401.pom";
          package = bnd_401;
        };
      }
    ];
  };
  meta = {
    mavenProvides = exposeMavenProvides finalAttrs;
    mavenProvidesInternal = {
      "org.codehaus.groovy:groovy:${finalAttrs.version}" = {
        "groovy-${finalAttrs.version}.jar" = "$out/lib/groovy-${finalAttrs.version}.jar";
        "groovy-${finalAttrs.version}.pom" = "${finalAttrs.src}/pom.xml";
      };
      "org.codehaus.groovy:groovy-all:${finalAttrs.version}" = {
        "groovy-all-${finalAttrs.version}.pom" = "$out/groovy-all-${finalAttrs.version}.pom";
      };
    };
  };
})
