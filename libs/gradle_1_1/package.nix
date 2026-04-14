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
  commons_codec_1_6,
  gradle_1_0,
}:
let
  version = "1.1";
  gradleModules = [
    "gradle-base-services"
    "gradle-cli"
    "gradle-core"
    "gradle-core-impl"
    "gradle-launcher"
    "gradle-messaging"
    "gradle-native"
    "gradle-open-api"
    "gradle-tooling-api"
    "gradle-wrapper"
  ];
  artifacts = [
    {
      path = "org/apache/httpcomponents/httpclient/4.2.1/httpclient-4.2.1.jar";
      hash = "sha256-iIXYJLyCcE+oX2WKozCCD3l7LF95ygrOFbAKFLgRazI=";
    }
    {
      path = "org/apache/httpcomponents/httpcore/4.2.1/httpcore-4.2.1.jar";
      hash = "sha256-gIaCbdI0nYPkkz/eOYllzf6HHrknjNthrFvIFB15fYQ=";
    }
    {
      path = "commons-codec/commons-codec/1.6/commons-codec-1.6.jar";
      package = "${commons_codec_1_6}/commons-codec-1.6.jar";
    }
    {
      path = "org/apache/maven/maven-settings-builder/3.0.4/maven-settings-builder-3.0.4.jar";
      hash = "sha256-o4pU7B5pow3fwUQ04K7Cdk/CaGaKvMDhMthmkqXc4+Q=";
    }
    {
      path = "org/apache/maven/maven-settings/3.0.4/maven-settings-3.0.4.jar";
      hash = "sha256-Pj3xf1315M4ee38gEcV9YdMo5lZ4VCreIEjw0PopXwk=";
    }
    {
      path = "org/apache/maven/maven-model/3.0.4/maven-model-3.0.4.jar";
      hash = "sha256-JraCXqc6xNexpvXmKsHBGw/CclBNpt3puo+JTNhH4cE=";
    }
    {
      path = "org/codehaus/plexus/plexus-utils/2.0.6/plexus-utils-2.0.6.jar";
      hash = "sha256-i5CfTKl4hkeUL4g9TlWbzGQhI/fGvNOEaYOi5GVGnDM=";
    }
    {
      path = "org/codehaus/plexus/plexus-interpolation/1.14/plexus-interpolation-1.14.jar";
      hash = "sha256-f8YzeNPoRmNhm5vtrOn5/niydsK+PGLKIkVEkpTIQXY=";
    }
    {
      path = "org/codehaus/plexus/plexus-component-annotations/1.5.5/plexus-component-annotations-1.5.5.jar";
      hash = "sha256-Tfemp75ks1u8z2C1wRVpf56jQh0iZ0rmcTXd43X8yh8=";
    }
    {
      path = "org/sonatype/plexus/plexus-cipher/1.4/plexus-cipher-1.4.jar";
      hash = "sha256-WhX9uiJmng/dBuENzOYyCHnh9zmPvJEM0Gd7UGcqeMQ=";
    }
    {
      path = "org/sonatype/plexus/plexus-sec-dispatcher/1.3/plexus-sec-dispatcher-1.3.jar";
      hash = "sha256-OwVZu4Qy8ok37+bKGT71SoUG0Addc/10BrmxFsahEGM=";
    }
    {
      path = "com/googlecode/jarjar/jarjar/1.3/jarjar-1.3.jar";
      hash = "sha256-QiXI7hvzB5xLB8dv4Dw+KICaIiBNtiSclBfvpPgEs6c=";
    }
    {
      path = "xerces/xercesImpl/2.9.1/xercesImpl-2.9.1.jar";
      hash = "sha256-auVAp8hcgUrGS+pIAWs6b0XJXUdl9Uf8wAU9w2yU7Vw=";
    }
    {
      path = "net/sourceforge/nekohtml/nekohtml/1.9.14/nekohtml-1.9.14.jar";
      hash = "sha256-irBIZFyPr3NUBHWvtRPXNU4bbg/K+Yu4QquBYF74D/0=";
    }
    {
      path = "xml-apis/xml-apis/1.3.04/xml-apis-1.3.04.jar";
      hash = "sha256-1ASqiB65xfek+1RuhOoRUGzUF6crWXLojv8X9D+fimQ=";
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
    tag = "v1.1";
    hash = "sha256-hVQZ/ZUye72yXU0BB3di3yD+a7mr+0pDIIzcSxrCoMk=";
  };

  nativeBuildInputs = [ jdk8_headless ];

  patches = [ ./gradle-1.1-direct-bootstrap.patch ];

  dontConfigure = true;

  buildPhase = ''
    runHook preBuild

    export JAVA_HOME=${jdk8_headless}
    export HOME="$TMPDIR/home"
    mkdir -p "$HOME" build/lib build/runtime/classes build/plugins/classes build/stubs

    cp ${gradle_1_0}/libexec/gradle/lib/*.jar build/lib/
    rm -f build/lib/gradle-*.jar
    rm -f build/lib/httpclient-*.jar build/lib/httpcore-*.jar build/lib/commons-codec-*.jar
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
      subprojects/messaging/src/main/java \
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

    for subproject in core core-impl launcher messaging; do
      if [ -d "subprojects/$subproject/src/main/resources" ]; then
        cp -a "subprojects/$subproject/src/main/resources/." build/runtime/classes/
      fi
    done

    mkdir -p build/runtime/classes/org/gradle
    cat > build/runtime/classes/org/gradle/build-receipt.properties <<EOF
    versionNumber=${version}
    buildTimestamp=20120807000000+0000
    commitId=direct-bootstrap
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
    cp build/plugins/gradle-plugins-${version}.jar "$gradleHome/lib/plugins/"
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
    description = "Gradle 1.1 runtime and base plugins built directly from source";
    homepage = "https://www.gradle.org/";
    sourceProvenance = with lib.sourceTypes; [ fromSource ];
    license = lib.licenses.asl20;
    mainProgram = "gradle";
    platforms = lib.platforms.unix;
  };
}
