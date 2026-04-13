{
  callPackage,
  fetchFromGitHub,
  buildMavenRepositoryFromLockFile,
  buildMavenRepository,
  jdk8_headless,
  ant,
  stdenv,writableTmpDirAsHomeHook,
}:
let
  inherit (buildMavenRepositoryFromLockFile.passthru) mergeDeps readDeps;
in
stdenv.mkDerivation (finalAttrs: {
  pname = "groovy";
  version = "1.8.9";
  src = fetchFromGitHub {
    owner = "apache";
    repo = "groovy";
    rev = "GROOVY_1_8_9";
    hash = "sha256-pG9jsyMEUMVoeqnI04Tk5g0Y5VRxBcTxVSw4HyGqF0E=";
  };
  sourceRoot = finalAttrs.src.name;
  buildPhase = ''
    runHook preBuild
    mkdir out
    cp -r ${finalAttrs.mavenRepository} m2-repo
    chmod -R a+w m2-repo
    ant -Dmaven.repo.local=$PWD/m2-repo install -DskipTests=true -DskipOsgi=true
    runHook postBuild
  '';
  patches = [
    ./a.patch
  ];
  postPatch = ''
    sed -i 's|<contains string="''${ant.version}" substring="1.1"></contains>||g' build.xml
    sed -i 's|\bParameter\b|org.codehaus.groovy.ast.Parameter|g' src/main/org/codehaus/groovy/vmplugin/v5/Java5.java
  '';
  nativeBuildInputs = [
    ant
    jdk8_headless
  ];
  # After deleting symlinks, left are what it published.
  installPhase = ''
    runHook preInstall
    find m2-repo -type l -delete
    for i in {1..10}; do find m2-repo -type d -empty -delete; done

    mkdir $out
    mv m2-repo $out/

    runHook postInstall
  '';
  mavenRepository = buildMavenRepository { dependencies = readDeps finalAttrs.passthru.mavenDeps; };
  passthru = {
    mavenDeps = mergeDeps [
      # remove biz.aQute:bnd:jar:0.0.401 biz.aQute:bnd:pom:0.0.401
      ./linux-m2.json
    ];
  };
})
