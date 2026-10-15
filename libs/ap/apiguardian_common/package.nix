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
  tag ? "r${version}",
  doCheck ? true,
  disabledTests ? [ ],
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "apiguardian-api";
  inherit version;

  src = fetchFromGitHub {
    owner = "apiguardian-team";
    repo = "apiguardian";
    inherit tag hash;
  };

  pomFile = fetchurl {
    url = "https://repo.maven.apache.org/maven2/org/apiguardian/apiguardian-api/${finalAttrs.version}/apiguardian-api-${finalAttrs.version}.pom";
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
    find src/main/java -name '*.java' ! -name 'module-info.java' | sort > sources.txt
    javac --release 8 -encoding UTF-8 -d classes @sources.txt

    (
      cd classes
      jar cf "../apiguardian-api-${finalAttrs.version}.jar" .
    )

    runHook postBuild
  '';

  checkPhase = ''
    runHook preCheck

    mkdir -p test-src test-classes
    cat << 'EOF' > test-src/ApiGuardianTest.java
    import org.junit.Test;
    import static org.junit.Assert.*;
    import java.lang.annotation.*;
    import org.apiguardian.api.*;

    public class ApiGuardianTest {
        @Test
        public void testAnnotationMetadata() {
            Target target = API.class.getAnnotation(Target.class);
            assertNotNull(target);
            Retention retention = API.class.getAnnotation(Retention.class);
            assertNotNull(retention);
            assertEquals(RetentionPolicy.RUNTIME, retention.value());
        }

        @Test
        public void testStatusEnum() {
            API.Status[] statuses = API.Status.values();
            assertEquals(5, statuses.length);
            assertEquals(API.Status.INTERNAL, API.Status.valueOf("INTERNAL"));
            assertEquals(API.Status.DEPRECATED, API.Status.valueOf("DEPRECATED"));
            assertEquals(API.Status.EXPERIMENTAL, API.Status.valueOf("EXPERIMENTAL"));
            assertEquals(API.Status.MAINTAINED, API.Status.valueOf("MAINTAINED"));
            assertEquals(API.Status.STABLE, API.Status.valueOf("STABLE"));
        }

        @API(status = API.Status.STABLE, since = "1.0")
        static class AnnotatedExample {}

        @Test
        public void testAnnotatedClass() {
            API api = AnnotatedExample.class.getAnnotation(API.class);
            assertNotNull(api);
            assertEquals(API.Status.STABLE, api.status());
            assertEquals("1.0", api.since());
        }
    }
    EOF

    ${lib.concatMapStringsSep "\n" (testMethod: ''
      substituteInPlace test-src/ApiGuardianTest.java \
        --replace-fail 'public void ${testMethod}()' '@org.junit.Ignore public void ${testMethod}()'
    '') disabledTests}

    javac --release 8 -encoding UTF-8 \
      -cp "./apiguardian-api-${finalAttrs.version}.jar:${junit_4}/share/java/junit.jar:${java-hamcrest}/share/java/hamcrest-3.0.jar" \
      -d test-classes test-src/ApiGuardianTest.java

    java -cp "test-classes:./apiguardian-api-${finalAttrs.version}.jar:${junit_4}/share/java/junit.jar:${java-hamcrest}/share/java/hamcrest-3.0.jar" \
      org.junit.runner.JUnitCore ApiGuardianTest

    runHook postCheck
  '';

  installPhase = ''
    runHook preInstall

    mkdir -p "$out"
    install -Dm644 "./apiguardian-api-${finalAttrs.version}.jar" "$out/apiguardian-api-${finalAttrs.version}.jar"
    install -Dm644 "${finalAttrs.pomFile}" "$out/apiguardian-api-${finalAttrs.version}.pom"

    runHook postInstall
  '';

  meta = with lib; {
    description = "API Guardian target and status annotations";
    homepage = "https://github.com/apiguardian-team/apiguardian";
    sourceProvenance = with sourceTypes; [ fromSource ];
    license = licenses.asl20;
    platforms = platforms.unix;
  };
})
