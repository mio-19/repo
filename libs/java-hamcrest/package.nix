{
  fetchFromGitHub,
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
  pname = "java-hamcrest";
  version = "3.0";

  src = fetchFromGitHub {
    owner = "hamcrest";
    repo = "JavaHamcrest";
    tag = "v${finalAttrs.version}";
    hash = "sha256-ntae6XWpD0wEs36YoPsfTl6cSR6ULl6dAJ5oZsV+ih0=";
  };

  nativeBuildInputs = [
    jdk
    stripJavaArchivesHook
  ];

  dontConfigure = true;

  buildPhase = ''
    runHook preBuild

    mkdir -p build/classes/META-INF

    find hamcrest/src/main/java -name "*.java" | sort > sources.txt
    javac \
      --release 8 \
      -encoding UTF-8 \
      -d build/classes \
      @sources.txt

    cp LICENSE build/classes/META-INF/LICENSE
    jar cf hamcrest-${finalAttrs.version}.jar -C build/classes .

    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall

    install -Dm644 hamcrest-${finalAttrs.version}.jar "$out/share/java/hamcrest-${finalAttrs.version}.jar"
    cat > "$out/share/java/hamcrest-${finalAttrs.version}.pom" <<EOF
    <project>
      <modelVersion>4.0.0</modelVersion>
      <groupId>org.hamcrest</groupId>
      <artifactId>hamcrest</artifactId>
      <version>${finalAttrs.version}</version>
    </project>
    EOF

    runHook postInstall
  '';

  doInstallCheck = true;
  installCheckPhase = checkMavenProvides finalAttrs;

  strictDeps = true;
  __structuredAttrs = true;

  meta = {
    homepage = "https://hamcrest.org/JavaHamcrest/";
    description = "Java library of matcher objects";
    platforms = lib.platforms.all;
    license = lib.licenses.bsd3;
    sourceProvenance = with lib.sourceTypes; [ fromSource ];
    mavenProvides = exposeMavenProvides finalAttrs;
    mavenProvidesInternal = {
      "org.hamcrest:hamcrest:${finalAttrs.version}" = {
        "hamcrest-${finalAttrs.version}.jar" = "$out/share/java/hamcrest-${finalAttrs.version}.jar";
        "hamcrest-${finalAttrs.version}.pom" = "$out/share/java/hamcrest-${finalAttrs.version}.pom";
      };
    };
  };
})
