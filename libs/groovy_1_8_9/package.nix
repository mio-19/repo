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
  ant_nixpkgs = callPackage ../ant/nixpkgs.nix { };
  bnd_384 = fetchurl {
    url = "https://repo1.maven.org/maven2/biz/aQute/bnd/0.0.384/bnd-0.0.384.pom";
    hash = "sha256-K1Q7NMOlTdxinjZ62KGVNRyGeBI2oB8rY1d45chT8Jo=";
  };
  bnd_401 = runCommand "bnd-0.0.401.pom" { } ''
    substitute ${bnd_384} $out --replace-fail '0.0.384' '0.0.401'
  '';
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
  patches = [
    ./a.patch
  ];
  postPatch = ''
    substituteInPlace build.xml \
      --replace-fail '<contains string="''${ant.version}" substring="1.1"></contains>' ""
    substituteInPlace src/main/org/codehaus/groovy/vmplugin/v5/Java5.java \
      --replace-fail 'Parameter[] params = makeParameters(compileUnit, m.getGenericParameterTypes(), m.getParameterTypes(), m.getParameterAnnotations());' \
        'org.codehaus.groovy.ast.Parameter[] params = makeParameters(compileUnit, m.getGenericParameterTypes(), m.getParameterTypes(), m.getParameterAnnotations());' \
      --replace-fail 'Parameter[] params = makeParameters(compileUnit, ctor.getGenericParameterTypes(), ctor.getParameterTypes(), ctor.getParameterAnnotations());' \
        'org.codehaus.groovy.ast.Parameter[] params = makeParameters(compileUnit, ctor.getGenericParameterTypes(), ctor.getParameterTypes(), ctor.getParameterAnnotations());' \
      --replace-fail 'private Parameter[] makeParameters(CompileUnit cu, Type[] types, Class[] cls, Annotation[][] parameterAnnotations) {' \
        'private org.codehaus.groovy.ast.Parameter[] makeParameters(CompileUnit cu, Type[] types, Class[] cls, Annotation[][] parameterAnnotations) {' \
      --replace-fail 'Parameter[] params = Parameter.EMPTY_ARRAY;' \
        'org.codehaus.groovy.ast.Parameter[] params = org.codehaus.groovy.ast.Parameter.EMPTY_ARRAY;' \
      --replace-fail 'params = new Parameter[types.length];' \
        'params = new org.codehaus.groovy.ast.Parameter[types.length];' \
      --replace-fail 'private Parameter makeParameter(CompileUnit cu, Type type, Class cl, Annotation[] annotations, int idx) {' \
        'private org.codehaus.groovy.ast.Parameter makeParameter(CompileUnit cu, Type type, Class cl, Annotation[] annotations, int idx) {' \
      --replace-fail 'Parameter parameter = new Parameter(cn, "param" + idx);' \
        'org.codehaus.groovy.ast.Parameter parameter = new org.codehaus.groovy.ast.Parameter(cn, "param" + idx);'
  '';
  buildPhase = ''
    runHook preBuild
    mkdir out
    cp -r ${finalAttrs.mavenRepository} m2-repo
    chmod -R a+w m2-repo
    ln -s ${bnd_401} m2-repo/biz/aQute/bnd/0.0.401/bnd-0.0.401.pom
    ${ant_nixpkgs}/bin/ant \
      -lib ${finalAttrs.mavenRepository}/antlr/antlr/2.7.6/antlr-2.7.6.jar \
      -Dmaven.repo.local=$PWD/m2-repo \
      install -DskipTests=true -DskipOsgi=true
    runHook postBuild
  '';
  nativeBuildInputs = [
    ant_nixpkgs
    jdk8_headless
  ];
  installPhase = ''
    runHook preInstall
    mkdir -p $out
    cp -r target/install/. $out/
    cp target/dist/groovy-${finalAttrs.version}.jar $out/
    cp target/dist/groovy-all-${finalAttrs.version}.jar $out/
    cp target/groovy-all.pom $out/groovy-all-${finalAttrs.version}.pom

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
