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
  disabledTests ? [ ],
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "reactive-streams";
  inherit version;

  src = fetchFromGitHub {
    owner = "reactive-streams";
    repo = "reactive-streams-jvm";
    inherit tag hash;
  };

  pomFile = fetchurl {
    url = "https://repo.maven.apache.org/maven2/org/reactivestreams/reactive-streams/${finalAttrs.version}/reactive-streams-${finalAttrs.version}.pom";
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
    javac --release 8 -encoding UTF-8 -d classes @sources.txt

    if [ -d api/src/main/java9 ]; then
      find api/src/main/java9 -name '*.java' ! -name 'module-info.java' | sort > sources9.txt
      javac --release 9 -encoding UTF-8 -cp classes -d classes @sources9.txt
    fi

    (
      cd classes
      jar cf "../reactive-streams-${finalAttrs.version}.jar" .
    )

    runHook postBuild
  '';

  checkPhase = ''
    runHook preCheck

    mkdir -p test-src test-classes
    cat << 'EOF' > test-src/ReactiveStreamsTest.java
    import org.junit.Test;
    import static org.junit.Assert.*;
    import org.reactivestreams.*;

    public class ReactiveStreamsTest {
        @Test
        public void testInterfacesDefined() {
            assertTrue(Publisher.class.isInterface());
            assertTrue(Subscriber.class.isInterface());
            assertTrue(Subscription.class.isInterface());
            assertTrue(Processor.class.isInterface());
            assertNotNull(FlowAdapters.class);
        }

        @Test
        public void testProcessorHierarchy() {
            assertTrue(Publisher.class.isAssignableFrom(Processor.class));
            assertTrue(Subscriber.class.isAssignableFrom(Processor.class));
        }

        @Test
        public void testCustomImplementation() {
            final boolean[] received = new boolean[] { false };
            Publisher<String> pub = new Publisher<String>() {
                @Override
                public void subscribe(Subscriber<? super String> s) {
                    s.onSubscribe(new Subscription() {
                        @Override public void request(long n) {}
                        @Override public void cancel() {}
                    });
                    s.onNext("hello");
                    s.onComplete();
                }
            };

            pub.subscribe(new Subscriber<String>() {
                @Override public void onSubscribe(Subscription s) {}
                @Override public void onNext(String t) { received[0] = "hello".equals(t); }
                @Override public void onError(Throwable t) {}
                @Override public void onComplete() {}
            });

            assertTrue(received[0]);
        }
    }
    EOF

    ${lib.concatMapStringsSep "\n" (testMethod: ''
      substituteInPlace test-src/ReactiveStreamsTest.java \
        --replace-fail 'public void ${testMethod}()' '@org.junit.Ignore public void ${testMethod}()'
    '') disabledTests}

    javac --release 9 -encoding UTF-8 \
      -cp "./reactive-streams-${finalAttrs.version}.jar:${junit_4}/share/java/junit.jar:${java-hamcrest}/share/java/hamcrest-3.0.jar" \
      -d test-classes test-src/ReactiveStreamsTest.java

    java -cp "test-classes:./reactive-streams-${finalAttrs.version}.jar:${junit_4}/share/java/junit.jar:${java-hamcrest}/share/java/hamcrest-3.0.jar" \
      org.junit.runner.JUnitCore ReactiveStreamsTest

    runHook postCheck
  '';

  installPhase = ''
    runHook preInstall

    mkdir -p "$out"
    install -Dm644 "./reactive-streams-${finalAttrs.version}.jar" "$out/reactive-streams-${finalAttrs.version}.jar"
    install -Dm644 "${finalAttrs.pomFile}" "$out/reactive-streams-${finalAttrs.version}.pom"

    runHook postInstall
  '';

  meta = with lib; {
    description = "Reactive Streams specification for the JVM";
    homepage = "https://www.reactive-streams.org/";
    sourceProvenance = with sourceTypes; [ fromSource ];
    license = licenses.mit0;
    platforms = platforms.unix;
  };
})
