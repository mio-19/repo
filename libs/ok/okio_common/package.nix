{
  animal_sniffer_annotations_1_24,
  fetchurl,
  java-hamcrest,
  jdk17_headless,
  jsr305_3_0_2,
  junit_4,
  lib,
  stdenv,
}:

{
  version,
  src,
  pomHash,
  extraBuildInputs ? [ ],
  extraClasspath ? [ ],
  testClasses ? [
    "okio.ByteStringTest"
    "okio.BufferTest"
    "okio.Utf8Test"
  ],
  disabledTests ? [ ],
  ...
}@args:

let
  pom = fetchurl {
    url = "https://repo.maven.apache.org/maven2/com/squareup/okio/okio/${version}/okio-${version}.pom";
    hash = pomHash;
  };
in
stdenv.mkDerivation (finalAttrs: {
  pname = "okio";
  inherit version src;

  nativeBuildInputs = [
    jdk17_headless
    junit_4
    java-hamcrest
    jsr305_3_0_2
    animal_sniffer_annotations_1_24
  ]
  ++ extraBuildInputs;

  dontConfigure = true;

  buildPhase = ''
    runHook preBuild
    export JAVA_HOME=${jdk17_headless.passthru.home}
    mkdir -p build/classes

    cp="${jsr305_3_0_2}/jsr305-3.0.2.jar:${animal_sniffer_annotations_1_24}/animal-sniffer-annotations-1.24.jar"
    for extra in ${toString extraClasspath}; do
      cp="$cp:$extra"
    done

    find okio/src/main/java -name "*.java" > sources.txt
    javac -encoding UTF-8 -cp "$cp" -d build/classes @sources.txt

    jar -cf okio-${version}.jar -C build/classes .
    runHook postBuild
  '';

  doCheck = true;
  checkPhase = ''
    runHook preCheck
    export JAVA_HOME=${jdk17_headless.passthru.home}
    mkdir -p build/test-classes

    testCp="${junit_4}/share/java/junit.jar:${java-hamcrest}/share/java/hamcrest-3.0.jar:build/classes:$cp"

    ${lib.concatMapStringsSep "\n" (m: ''
      find okio/src/test/java -name "*.java" -exec grep -l "${m}" {} + | while read -r f; do
        substituteInPlace "$f" --replace-fail "public void ${m}" "@org.junit.Ignore public void ${m}"
      done
    '') disabledTests}

    find okio/src/test/java -name "*.java" > test-sources.txt
    javac -encoding UTF-8 -cp "$testCp" -d build/test-classes @test-sources.txt

    java -cp "build/test-classes:$testCp" org.junit.runner.JUnitCore ${toString testClasses}
    runHook postCheck
  '';

  installPhase = ''
    runHook preInstall
    install -Dm644 okio-${version}.jar $out/okio-${version}.jar
    install -Dm644 ${pom} $out/okio-${version}.pom
    runHook postInstall
  '';

  meta = with lib; {
    description = "A modern I/O library for Android, Java, and Kotlin Multiplatform";
    homepage = "https://square.github.io/okio/";
    license = licenses.asl20;
    platforms = platforms.unix;
    sourceProvenance = with sourceTypes; [ fromSource ];
  };
})
