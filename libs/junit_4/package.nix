{
  fetchFromGitHub,
  java-hamcrest,
  jdk,
  lib,
  libsUtils,
  stdenvNoCC,
  stripJavaArchivesHook,
}:

let
  inherit (libsUtils) checkMavenProvides exposeMavenProvides;
in
stdenvNoCC.mkDerivation (finalAttrs: {
  pname = "junit";
  version = "4.13.2";

  src = fetchFromGitHub {
    owner = "junit-team";
    repo = "junit4";
    tag = "r${finalAttrs.version}";
    hash = "sha256-A6ZbmsECwP/hYqmIoU3rDvEX3V9Dx3FtCgAxpv8n8+Q=";
  };

  nativeBuildInputs = [
    jdk
    stripJavaArchivesHook
  ];

  propagatedBuildInputs = [ java-hamcrest ];

  postPatch = ''
    for f in \
      src/main/java/org/junit/internal/matchers/ThrowableMessageMatcher.java \
      src/main/java/org/junit/internal/matchers/StacktracePrintingMatcher.java \
      src/main/java/org/junit/internal/matchers/ThrowableCauseMatcher.java; do
      substituteInPlace "$f" \
        --replace-fail 'import org.hamcrest.Factory;' "" \
        --replace-fail '    @Factory' ""
    done

    substituteInPlace src/main/java/org/junit/matchers/JUnitMatchers.java \
      --replace-fail 'return CoreMatchers.everyItem(elementMatcher);' \
      'return (Matcher<Iterable<T>>) (Object) CoreMatchers.everyItem(elementMatcher);'
  '';

  buildPhase = ''
    runHook preBuild

    mkdir -p build/classes

    find src/main/java -name "*.java" | sort > sources.txt
    javac \
      --release 8 \
      -classpath "$(find ${java-hamcrest}/share/java -name '*.jar' | sort | tr '\n' ':')" \
      -encoding ISO-8859-1 \
      -d build/classes \
      @sources.txt

    if [ -d src/main/resources ]; then
      cp -r src/main/resources/. build/classes/
    fi

    jar cf junit-${finalAttrs.version}.jar -C build/classes .

    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall

    install -Dm644 junit-${finalAttrs.version}.jar "$out/share/java/junit-${finalAttrs.version}.jar"
    install -Dm644 pom.xml "$out/share/java/junit-${finalAttrs.version}.pom"
    ln -s junit-${finalAttrs.version}.jar "$out/share/java/junit.jar"

    runHook postInstall
  '';

  doInstallCheck = true;
  installCheckPhase = checkMavenProvides finalAttrs;

  strictDeps = true;
  __structuredAttrs = true;

  meta = {
    description = "JUnit 4 testing framework for Java";
    homepage = "https://junit.org/junit4/";
    license = lib.licenses.epl10;
    platforms = lib.platforms.all;
    sourceProvenance = with lib.sourceTypes; [ fromSource ];
    mavenProvides = exposeMavenProvides finalAttrs;
    mavenProvidesInternal = {
      "junit:junit:${finalAttrs.version}" = {
        "junit-${finalAttrs.version}.jar" = "$out/share/java/junit-${finalAttrs.version}.jar";
        "junit-${finalAttrs.version}.pom" = "$out/share/java/junit-${finalAttrs.version}.pom";
      };
    };
  };
})
