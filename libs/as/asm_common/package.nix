{
  fetchurl,
  java-hamcrest,
  jdk25_headless,
  junit_4,
  lib,
  stdenv,
}:
{
  artifactId,
  version,
  srcHash,
  pomHash,
  classpath ? [ ],
  testClass ? null,
  testSource ? null,
  doCheck ? true,
}:

let
  defaultTestClass = "AsmTest";
  defaultTestSource = ''
    import org.junit.Test;
    import static org.junit.Assert.*;
    import org.objectweb.asm.*;

    public class AsmTest {
        @Test
        public void testClassWriterAndReader() throws Exception {
            ClassWriter cw = new ClassWriter(0);
            cw.visit(Opcodes.V1_8, Opcodes.ACC_PUBLIC, "com/example/Generated", null, "java/lang/Object", null);
            cw.visitEnd();
            byte[] bytes = cw.toByteArray();
            assertNotNull(bytes);
            assertTrue(bytes.length > 0);

            ClassReader cr = new ClassReader(bytes);
            assertEquals("com/example/Generated", cr.getClassName());
        }
    }
  '';
  actualTestClass = if testClass != null then testClass else defaultTestClass;
  actualTestSource = if testSource != null then testSource else defaultTestSource;
  shouldCheck = doCheck && (artifactId == "asm" || testSource != null);
in
stdenv.mkDerivation (finalAttrs: {
  pname = artifactId;
  inherit version;

  src = fetchurl {
    url = "https://repo.maven.apache.org/maven2/org/ow2/asm/${artifactId}/${finalAttrs.version}/${artifactId}-${finalAttrs.version}-sources.jar";
    hash = srcHash;
  };

  pom = fetchurl {
    url = "https://repo.maven.apache.org/maven2/org/ow2/asm/${artifactId}/${finalAttrs.version}/${artifactId}-${finalAttrs.version}.pom";
    hash = pomHash;
  };

  nativeBuildInputs = [
    jdk25_headless
    junit_4
    java-hamcrest
  ];

  dontConfigure = true;
  dontUnpack = true;

  buildPhase = ''
    runHook preBuild
    export JAVA_HOME=${jdk25_headless.passthru.home}
    tmp="$(mktemp -d)"

    mkdir -p "$tmp/src" "$tmp/classes"
    cd "$tmp/src"
    jar xf "$src"

    find . -name '*.java' > "$tmp/sources.txt"
    javac --release 8 \
      ${lib.optionalString (classpath != [ ]) "-cp ${lib.concatStringsSep ":" classpath}"} \
      -d "$tmp/classes" \
      @"$tmp/sources.txt"

    (
      cd "$tmp/classes"
      jar cf "$tmp/${artifactId}-${finalAttrs.version}.jar" .
    )
    runHook postBuild
  '';

  doCheck = shouldCheck;
  checkPhase = ''
        runHook preCheck
        export JAVA_HOME=${jdk25_headless.passthru.home}
        mkdir -p "$tmp/test"
        cat > "$tmp/test/${actualTestClass}.java" << 'EOF'
    ${actualTestSource}
    EOF

        testCp="${junit_4}/share/java/junit.jar:${java-hamcrest}/share/java/hamcrest-3.0.jar:$tmp/classes${
          lib.optionalString (classpath != [ ]) ":${lib.concatStringsSep ":" classpath}"
        }"
        javac --release 8 -cp "$testCp" -d "$tmp/test" "$tmp/test/${actualTestClass}.java"
        java -cp "$tmp/test:$testCp" org.junit.runner.JUnitCore "${actualTestClass}"
        runHook postCheck
  '';

  installPhase = ''
    runHook preInstall
    mkdir -p "$out"
    install -Dm644 "$tmp/${artifactId}-${finalAttrs.version}.jar" "$out/${artifactId}-${finalAttrs.version}.jar"
    install -Dm644 "$pom" "$out/${artifactId}-${finalAttrs.version}.pom"
    runHook postInstall
  '';

  meta = with lib; {
    description = "Java bytecode manipulation framework";
    homepage = "https://asm.ow2.io/";
    license = licenses.bsd3;
    platforms = platforms.unix;
    sourceProvenance = with sourceTypes; [ fromSource ];
  };
})
