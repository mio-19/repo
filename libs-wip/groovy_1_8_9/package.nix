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
}:
let
  inherit (buildMavenRepositoryFromLockFile.passthru) mergeDeps readDeps;
  bnd_384 = fetchurl {
    url = "https://repo1.maven.org/maven2/biz/aQute/bnd/0.0.384/bnd-0.0.384.pom";
    hash = "sha256-K1Q7NMOlTdxinjZ62KGVNRyGeBI2oB8rY1d45chT8Jo=";
  };
  bnd_401 = runCommand "bnd-0.0.401.pom" {} ''
      substitute ${bnd_384} $out --replace-fail '0.0.384' '0.0.401'
    '';
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
  patches = [
    ./a.patch
  ];
  postPatch = ''
    sed -i 's|<contains string="''${ant.version}" substring="1.1"></contains>||g' build.xml
    sed -i 's|\bParameter\b|org.codehaus.groovy.ast.Parameter|g' src/main/org/codehaus/groovy/vmplugin/v5/Java5.java
    substituteInPlace build.xml --replace-fail '<target name="stagedcompile" depends="-init,ensureGrammars,-jvm14BuildWarning,exceptionUtils" unless="uber">' '<target name="stagedcompile" depends="-init,-jvm14BuildWarning,exceptionUtils" unless="uber">'
  '';
  buildPhase = ''
    runHook preBuild
    mkdir out
    cp -r ${finalAttrs.mavenRepository} m2-repo
    chmod -R a+w m2-repo
    ln -s ${bnd_401} m2-repo/biz/aQute/bnd/0.0.401/bnd-0.0.401.pom
    ant -Dmaven.repo.local=$PWD/m2-repo install -DskipTests=true -DskipOsgi=true
    runHook postBuild
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
      ./more.json
      # remove biz.aQute:bnd:jar:0.0.401 biz.aQute:bnd:pom:0.0.401
      ./linux-m2.json
      # commons-collections:commons-collections:jar:2.1
      ../maven_3_3_9/linux-m2.json
    ];
  };
})
