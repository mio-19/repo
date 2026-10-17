{
  fetchFromGitHub,
  fetchurl,
  jdk25_headless,
  junit_4,
  java-hamcrest,
  lib,
  stdenv,
}:
{
  version,
  hash,
  pomHash,
  tag ? "v${version}",
  doCheck ? true,
  extraClasspath ? [ ],
  disabledTests ? [ ],
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "perfmark-api";
  inherit version;

  src = fetchFromGitHub {
    owner = "perfmark";
    repo = "perfmark";
    inherit tag hash;
  };

  pomFile = fetchurl {
    url = "https://repo.maven.apache.org/maven2/io/perfmark/perfmark-api/${finalAttrs.version}/perfmark-api-${finalAttrs.version}.pom";
    hash = pomHash;
  };

  nativeBuildInputs = [ jdk25_headless ];
  nativeCheckInputs = lib.optionals doCheck [
    junit_4
    java-hamcrest
  ];

  inherit doCheck;

  buildPhase = ''
    runHook preBuild

    mkdir -p classes
    find api/src/main/java -name '*.java' ! -name 'module-info.java' | sort > sources.txt
    javac --release 8 -encoding UTF-8 \
      ${lib.optionalString (extraClasspath != [ ]) "-cp ${lib.concatStringsSep ":" extraClasspath}"} \
      -d classes @sources.txt

    (
      cd classes
      jar cf "../perfmark-api-${finalAttrs.version}.jar" .
    )

    runHook postBuild
  '';

  checkPhase = ''
    runHook preCheck

    mkdir -p test-src test-classes
    cat << 'EOF' > test-src/PerfMarkApiTest.java
    import org.junit.Test;
    import static org.junit.Assert.*;
    import io.perfmark.*;

    public class PerfMarkApiTest {
        @Test
        public void testTaskLifecycle() {
            PerfMark.startTask("myTask");
            PerfMark.event("myEvent");
            PerfMark.stopTask("myTask");
        }

        @Test
        public void testTagCreation() {
            Tag tag1 = PerfMark.createTag("tagName", 123);
            assertNotNull(tag1);
            Tag tag2 = PerfMark.createTag("tagName");
            assertNotNull(tag2);
            PerfMark.attachTag(tag1);
            PerfMark.attachTag(tag2);
        }

        @Test
        public void testLink() {
            Link link = PerfMark.linkOut();
            assertNotNull(link);
            PerfMark.linkIn(link);
        }
    }
    EOF

    ${lib.concatMapStringsSep "\n" (testMethod: ''
      substituteInPlace test-src/PerfMarkApiTest.java \
        --replace-fail 'public void ${testMethod}()' '@org.junit.Ignore public void ${testMethod}()'
    '') disabledTests}

    javac --release 8 -encoding UTF-8 \
      -cp "./perfmark-api-${finalAttrs.version}.jar:${junit_4}/share/java/junit.jar:${java-hamcrest}/share/java/hamcrest-3.0.jar${
        lib.optionalString (extraClasspath != [ ]) ":${lib.concatStringsSep ":" extraClasspath}"
      }" \
      -d test-classes test-src/PerfMarkApiTest.java

    java -cp "test-classes:./perfmark-api-${finalAttrs.version}.jar:${junit_4}/share/java/junit.jar:${java-hamcrest}/share/java/hamcrest-3.0.jar${
      lib.optionalString (extraClasspath != [ ]) ":${lib.concatStringsSep ":" extraClasspath}"
    }" \
      org.junit.runner.JUnitCore PerfMarkApiTest

    runHook postCheck
  '';

  installPhase = ''
    runHook preInstall

    mkdir -p "$out"
    install -Dm644 "./perfmark-api-${finalAttrs.version}.jar" "$out/perfmark-api-${finalAttrs.version}.jar"
    install -Dm644 "${finalAttrs.pomFile}" "$out/perfmark-api-${finalAttrs.version}.pom"

    runHook postInstall
  '';

  meta = with lib; {
    description = "Low overhead tracing library for Java";
    homepage = "https://github.com/perfmark/perfmark";
    sourceProvenance = with sourceTypes; [ fromSource ];
    license = licenses.asl20;
    platforms = platforms.unix;
  };
})
