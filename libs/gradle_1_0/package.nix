{
  lib,
  stdenv,
  fetchFromGitHub,
  fetchurl,
  buildMavenRepository,
  jdk8_headless,
  coreutils,
  findutils,
  gnugrep,
  gnused,
  which,
  commons_lang_2_6,
  gradle_0_9,
}:
let
  defaultRepo = "https://repo1.maven.org/maven2";
  version = "1.0";
  gradleModules = [
    "gradle-base-services"
    "gradle-cli"
    "gradle-core"
    "gradle-core-impl"
    "gradle-launcher"
    "gradle-native"
    "gradle-open-api"
    "gradle-tooling-api"
    "gradle-wrapper"
  ];
  artifacts = [
    {
      path = "org/codehaus/groovy/groovy-all/1.8.6/groovy-all-1.8.6.jar";
      hash = "sha256-aRWGR+WLdBRzUjCjKa1dPvUZNvzww+TxlfP+xfNhyFg=";
    }
    {
      path = "commons-lang/commons-lang/2.6/commons-lang-2.6.jar";
      package = "${commons_lang_2_6}/commons-lang-2.6.jar";
    }
    {
      path = "net/java/dev/jna/jna/3.2.7/jna-3.2.7.jar";
      hash = "sha256-cisx0MixSn5+JPMyyI59xljBcD9+A4E2cLnMic55VgY=";
    }
    {
      path = "com/google/guava/guava/11.0.1/guava-11.0.1.jar";
      hash = "sha256-qnzvnSugEQott74PtuZ5zXH2om/Dup2ncV9B0zAN7x0=";
    }
    {
      path = "asm/asm-all/3.3.1/asm-all-3.3.1.jar";
      hash = "sha256-KlzbAiPXqJk5YhiRACU786Wr1HT2sZZENByap9Q1Tsw=";
    }
    {
      path = "org/apache/httpcomponents/httpclient/4.1.2/httpclient-4.1.2.jar";
      hash = "sha256-2yHL1hiskPxKprkuGrwPKS09QECpUQvh1uJyPp/fvgo=";
    }
    {
      path = "org/apache/httpcomponents/httpcore/4.1.2/httpcore-4.1.2.jar";
      hash = "sha256-UaFvcEq0fFs+uUsfN+u/vtZNJdr0l1sW7T4D3WgmL7o=";
    }
    {
      path = "jcifs/jcifs/1.3.17/jcifs-1.3.17.jar";
      hash = "sha256-EmA8nf56PRay1/Hfi/WwFocosVvkQTgssaKyCf3gxVM=";
    }
    {
      path = "net/jcip/jcip-annotations/1.0/jcip-annotations-1.0.jar";
      hash = "sha256-vlgFOSBgxxR0v2yaZ6CZRxJ00wuD7vhL/E4IiaTx3MA=";
    }
  ];

  artifactJars = buildMavenRepository {
    dependencies = builtins.listToAttrs (
      map (artifact: {
        name = artifact.path;
        value =
          let
            repo = artifact.repo or defaultRepo;
          in
          {
            layout = artifact.path;
            url = "${repo}/${artifact.path}";
            hash = artifact.hash or lib.fakeHash;
          }
          // lib.optionalAttrs (artifact ? package) {
            package = artifact.package;
          };
      }) artifacts
    );
    pathMap = baseNameOf;
  };
in
stdenv.mkDerivation {
  pname = "gradle";
  inherit version;

  src = fetchFromGitHub {
    owner = "gradle";
    repo = "gradle";
    tag = "v1.0";
    hash = "sha256-TNBjVxHJM+mxxdakrWC67Rwq+sF905iq0W7Yslgf/CE=";
  };

  nativeBuildInputs = [ jdk8_headless ];

  patches = [ ./gradle-1.0-direct-bootstrap.patch ];

  dontConfigure = true;

  buildPhase = ''
    runHook preBuild

    export JAVA_HOME=${jdk8_headless}
    export HOME="$TMPDIR/home"
    mkdir -p "$HOME" build/lib build/runtime/classes build/plugins/classes build/stubs

    cp ${gradle_0_9}/libexec/gradle/lib/*.jar build/lib/
    rm -f build/lib/gradle-*.jar
    rm -f build/lib/groovy-all-*.jar build/lib/commons-lang-*.jar build/lib/jna-[0-9]*.jar build/lib/asm-all-*.jar
    rm -f build/lib/google-collections-*.jar
    cp ${artifactJars}/*.jar build/lib/

    mkdir -p build/stubs/org/gradle/gradleplugin/userinterface/swing/standalone
    cat > build/stubs/org/gradle/gradleplugin/userinterface/swing/standalone/BlockingApplication.java <<'EOF'
    package org.gradle.gradleplugin.userinterface.swing.standalone;

    public class BlockingApplication {
        public static void launchAndBlock() {
            throw new UnsupportedOperationException("Gradle GUI is not part of this bootstrap build");
        }
    }
    EOF

    find \
      build/stubs \
      subprojects/base-services/src/main/java \
      subprojects/cli/src/main/java \
      subprojects/native/src/main/java \
      subprojects/open-api/src/main/groovy \
      subprojects/core/src/main/groovy \
      subprojects/core-impl/src/main/groovy \
      subprojects/tooling-api/src/main/java \
      subprojects/wrapper/src/main/java \
      subprojects/launcher/src/main/java \
      -type f \( -name '*.groovy' -o -name '*.java' \) | sort > build/runtime-sources.txt
    find \
      subprojects/plugins/src/main/groovy \
      -type f \( -name '*.groovy' -o -name '*.java' \) | sort > build/plugins-sources.txt

    compileClasspath="$(printf '%s:' build/lib/*.jar)''${JAVA_HOME}/lib/openjdk/lib/tools.jar"
    "''$JAVA_HOME/bin/java" -noverify -Dfile.encoding=UTF-8 -Xmx2048m -classpath "$compileClasspath" \
      org.codehaus.groovy.tools.FileSystemCompiler \
      --classpath "$compileClasspath" \
      --encoding UTF-8 \
      -j \
      -d build/runtime/classes \
      @build/runtime-sources.txt

    pluginsClasspath="build/runtime/classes:$compileClasspath"
    "''$JAVA_HOME/bin/java" -noverify -Dfile.encoding=UTF-8 -Xmx1536m -classpath "$pluginsClasspath" \
      org.codehaus.groovy.tools.FileSystemCompiler \
      --classpath "$pluginsClasspath" \
      --encoding UTF-8 \
      -j \
      -d build/plugins/classes \
      @build/plugins-sources.txt

    cp -a subprojects/plugins/src/main/resources/. build/plugins/classes/

    for subproject in core core-impl launcher; do
      if [ -d "subprojects/$subproject/src/main/resources" ]; then
        cp -a "subprojects/$subproject/src/main/resources/." build/runtime/classes/
      fi
    done

    mkdir -p build/runtime/classes/org/gradle
    cat > build/runtime/classes/org/gradle/releases.xml <<EOF
    <releases>
      <next version="1.1"/>
      <current version="${version}" build-time="20120612000000+0000" type="final"/>
    </releases>
    EOF
    printf 'plugins=gradle-plugins\n' > build/runtime/classes/gradle-plugins.properties

    runtime="$(cd build/lib && ls *.jar | grep -v '^gradle-' | paste -sd, -)"
    for module in ${lib.escapeShellArgs gradleModules}; do
      {
        printf 'runtime=%s\n' "$runtime"
        printf 'projects=\n'
      } > "build/runtime/classes/$module-classpath.properties"
    done
    {
      printf 'runtime=%s\n' "$runtime"
      printf 'projects=\n'
    } > build/plugins/classes/gradle-plugins-classpath.properties

    (
      cd build/runtime/classes
      "''$JAVA_HOME/bin/jar" cf ../gradle-runtime-${version}.jar .
    )
    (
      cd build/plugins/classes
      "''$JAVA_HOME/bin/jar" cf ../gradle-plugins-${version}.jar .
    )

    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall

    gradleHome="$out/libexec/gradle"
    mkdir -p "$gradleHome/lib/plugins" "$out/bin"

    for module in ${lib.escapeShellArgs gradleModules}; do
      cp build/runtime/gradle-runtime-${version}.jar "$gradleHome/lib/$module-${version}.jar"
    done
    cp build/plugins/gradle-plugins-${version}.jar "$gradleHome/lib/"
    cp build/lib/*.jar "$gradleHome/lib/"

    cat > "$out/bin/gradle" <<'EOF'
    #!${stdenv.shell}
    export JAVA_HOME="''${JAVA_HOME:-${jdk8_headless}}"
    export PATH="${
      lib.makeBinPath [
        coreutils
        findutils
        gnugrep
        gnused
        which
        jdk8_headless
      ]
    }:''$PATH"
    exec "''$JAVA_HOME/bin/java" \
      -noverify \
      -classpath "${placeholder "out"}/libexec/gradle/lib/gradle-core-${version}.jar" \
      org.gradle.launcher.GradleMain \
      "''$@"
    EOF
    chmod +x "$out/bin/gradle"

    runHook postInstall
  '';

  meta = {
    description = "Gradle 1.0 runtime and launcher built directly from source";
    homepage = "https://www.gradle.org/";
    sourceProvenance = with lib.sourceTypes; [ fromSource ];
    license = lib.licenses.asl20;
    mainProgram = "gradle";
    platforms = lib.platforms.unix;
  };
}
