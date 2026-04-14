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
  ant_1_9_3,
  gradle_1_12,
  slf4j_1_7_5,
}:
let
  version = "2.0";
  gradleModules = [
    "gradle-base-services"
    "gradle-cli"
    "gradle-core"
    "gradle-core-impl"
    "gradle-launcher"
    "gradle-messaging"
    "gradle-native"
    "gradle-plugin-use"
    "gradle-resources"
    "gradle-resources-http"
    "gradle-tooling-api"
    "gradle-wrapper"
  ];
  defaultRepo = "https://repo1.maven.org/maven2";
  gradleRepo = "https://repo.gradle.org/gradle/libs-releases";
  artifacts = [
    {
      path = "org/apache/ant/ant/1.9.3/ant-1.9.3.jar";
      package = "${ant_1_9_3}/ant-1.9.3.jar";
    }
    {
      path = "org/apache/ant/ant-launcher/1.9.3/ant-launcher-1.9.3.jar";
      package = "${ant_1_9_3}/ant-launcher-1.9.3.jar";
    }
    {
      path = "org/codehaus/groovy/groovy-all/2.3.2/groovy-all-2.3.2.jar";
      hash = "sha256-fyBWwA+8EsU5T2vZkcUS7lLrTJsMtrHO6cggnw8wp4Y=";
    }
    {
      path = "com/google/guava/guava-jdk5/17.0/guava-jdk5-17.0.jar";
      hash = "sha256-Wb9FZUe23aPO2WjLVvfy0+FEdOLeKWCjLEfjHB5FbGE=";
    }
    {
      path = "org/ow2/asm/asm-all/5.0.2/asm-all-5.0.2.jar";
      hash = "sha256-IIybCpWp90qDy59mDbAIdEGVxvWSSDwbvRp6CQhXrv4=";
    }
    {
      path = "com/google/code/gson/gson/2.2.4/gson-2.2.4.jar";
      hash = "sha256-wDKM0Hyp42OlrNAMHPSv6M9VS9bTc4NJgboFzr7Gh/s=";
    }
    {
      path = "org/slf4j/slf4j-api/1.7.5/slf4j-api-1.7.5.jar";
      package = "${slf4j_1_7_5}/slf4j-api-1.7.5.jar";
    }
    {
      path = "org/slf4j/jcl-over-slf4j/1.7.5/jcl-over-slf4j-1.7.5.jar";
      package = "${slf4j_1_7_5}/jcl-over-slf4j-1.7.5.jar";
    }
    {
      path = "org/slf4j/jul-to-slf4j/1.7.5/jul-to-slf4j-1.7.5.jar";
      package = "${slf4j_1_7_5}/jul-to-slf4j-1.7.5.jar";
    }
    {
      path = "org/slf4j/log4j-over-slf4j/1.7.5/log4j-over-slf4j-1.7.5.jar";
      package = "${slf4j_1_7_5}/log4j-over-slf4j-1.7.5.jar";
    }
    {
      path = "ch/qos/logback/logback-core/1.0.9/logback-core-1.0.9.jar";
      hash = "sha256-AQZCyIuhJL4EsN0qhRbKOMzMfIhxXThaOd+Zp4l7I5o=";
    }
    {
      path = "ch/qos/logback/logback-classic/1.0.9/logback-classic-1.0.9.jar";
      hash = "sha256-/6zdn0ypor6SjXU7OUQptJs94yqCONWE5OtGr0WPJs4=";
    }
    {
      path = "org/apache/httpcomponents/httpclient/4.2.2/httpclient-4.2.2.jar";
      hash = "sha256-nQ6BVGHvyPyapd5N2prinQdkMLLpPiaKMdekfMAKMc8=";
    }
    {
      path = "org/apache/httpcomponents/httpcore/4.2.2/httpcore-4.2.2.jar";
      hash = "sha256-wyu/AW8e7AWB/rsXfHYcL2V9ljXREK/92MYzgkJeUPA=";
    }
    {
      path = "com/esotericsoftware/kryo/kryo/2.20/kryo-2.20.jar";
      hash = "sha256-pmgOUNqk2AoFZ/9bbVaTAgvk0B4R8m7UDy1aT419EZg=";
    }
    {
      path = "com/esotericsoftware/reflectasm/reflectasm/1.07/reflectasm-1.07-shaded.jar";
      hash = "sha256-CKcOrbSydO2u/BGUwfdXBiGlGwqaoDaqFdzbe5J+fHY=";
    }
    {
      path = "org/objenesis/objenesis/1.2/objenesis-1.2.jar";
      hash = "sha256-jGXCN1eBSbh8au3yvZOkkl6Ny43X7FsML56vbP0JunA=";
    }
    {
      repo = gradleRepo;
      path = "net/rubygrapefruit/native-platform/0.10/native-platform-0.10.jar";
      hash = "sha256-WwYqIGc54rsrpD6ho55IzVB/GQM//54p+As54j7SqZM=";
    }
    {
      repo = gradleRepo;
      path = "net/rubygrapefruit/native-platform-linux-amd64/0.10/native-platform-linux-amd64-0.10.jar";
      hash = "sha256-2uZzlDsSuxrMZo4vWZy/FCc7xSbHVHnBJ2pejCvplvs=";
    }
    {
      path = "com/googlecode/jatl/jatl/0.2.2/jatl-0.2.2.jar";
      hash = "sha256-kVRAXkAurOll2qLnrc8vbyh9QVYiIbTu/zbxbgV8yik=";
    }
    {
      path = "org/apache/maven/maven-core/3.0.4/maven-core-3.0.4.jar";
      hash = "sha256-PdeVwK2XQqC+ZaKl7CJCjVndKokadWWulPZGYeN0BSg=";
    }
    {
      path = "org/apache/maven/maven-model-builder/3.0.4/maven-model-builder-3.0.4.jar";
      hash = "sha256-tPHTrlPCkOGuRWlMXOLRe/jVd/9ezg+aoM/+FRpu9Oc=";
    }
    {
      path = "org/apache/maven/maven-artifact/3.0.4/maven-artifact-3.0.4.jar";
      hash = "sha256-PBmalq+VUIcnJPQcBT14Od/MZRLncE+hbGdTY8QUZ5Y=";
    }
    {
      path = "org/apache/maven/maven-compat/3.0.4/maven-compat-3.0.4.jar";
      hash = "sha256-otAjeNQT2eh4M3gIIBY5AsW+Sw88RLZd52CPR82UWZ8=";
    }
    {
      path = "org/apache/maven/maven-repository-metadata/3.0.4/maven-repository-metadata-3.0.4.jar";
      hash = "sha256-olxNsnz/2p6SKdsWixGQ1qPlQ58/Z9av7D35Rw4HUtU=";
    }
    {
      path = "org/apache/maven/maven-plugin-api/3.0.4/maven-plugin-api-3.0.4.jar";
      hash = "sha256-Tl7n96t+Q/aReISJ5Z8tpKMi4+NfKi2LcUrZKfYk7q0=";
    }
    {
      path = "org/apache/maven/maven-aether-provider/3.0.4/maven-aether-provider-3.0.4.jar";
      hash = "sha256-M/9Kq70NAuTdgnnNqPNmxpkVMCvEu5e8AYFKmF9cBkM=";
    }
    {
      path = "org/apache/maven/wagon/wagon-provider-api/2.2/wagon-provider-api-2.2.jar";
      hash = "sha256-akYHbwTH2alIkkSTcg+/3JOTu7JwgLDaZ64pr5zq0a8=";
    }
    {
      path = "org/sonatype/aether/aether-api/1.13.1/aether-api-1.13.1.jar";
      hash = "sha256-ro3IAjJ3H4kT/r+kEMVxnpuo3tgfuZeI4hT9Z2274T8=";
    }
    {
      path = "org/sonatype/aether/aether-impl/1.13.1/aether-impl-1.13.1.jar";
      hash = "sha256-hlURmUgFgn6I8yeUSgiRQrt/PYjN4nG6Pc63MssTepM=";
    }
    {
      path = "org/sonatype/aether/aether-spi/1.13.1/aether-spi-1.13.1.jar";
      hash = "sha256-1d5OKZvlp5/rHb6P84FANMbkQxS0wAuS/6jZdXbe1bM=";
    }
    {
      path = "org/sonatype/aether/aether-util/1.13.1/aether-util-1.13.1.jar";
      hash = "sha256-aHeZoM6Yi+6ejrmuC6hwMArcARQkitSkMnvbYl0n4BA=";
    }
    {
      path = "org/apache/xbean/xbean-reflect/3.4/xbean-reflect-3.4.jar";
      hash = "sha256-F+DvoYcScDRiMZf7iMUMMNO6piuqDwfW7GkwR6yS7Ds=";
    }
    {
      path = "org/codehaus/plexus/plexus-container-default/1.5.5/plexus-container-default-1.5.5.jar";
      hash = "sha256-aRl0hs2AvrVLTg/KuqMl7C1OJjbpskXEckNch6EJMc8=";
    }
    {
      path = "org/codehaus/plexus/plexus-classworlds/2.4/plexus-classworlds-2.4.jar";
      hash = "sha256-JZ1SiilyLKtjSdfn1DLj/Uh3wIf/ywSYWmYS6XAju6g=";
    }
    {
      path = "org/sonatype/plexus/plexus-cipher/1.7/plexus-cipher-1.7.jar";
      hash = "sha256-EUhZhh/xD5h7iA1vNOMhUnSvPMkrOnODHITVluN8ZRE=";
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
    tag = "v2.0";
    hash = "sha256-Y+H/eSOaXnhBmlKzg+TIsV7lgq1Ldzq6L/2zv8/jqtQ=";
  };

  nativeBuildInputs = [ jdk8_headless ];

  patches = [ ./gradle-2.0-direct-bootstrap.patch ];

  dontConfigure = true;

  buildPhase = ''
    runHook preBuild

    export JAVA_HOME=${jdk8_headless}
    export HOME="$TMPDIR/home"
    mkdir -p "$HOME" build/lib build/runtime/classes build/plugins/classes build/stubs

    cp ${gradle_1_12}/libexec/gradle/lib/*.jar ${gradle_1_12}/libexec/gradle/lib/plugins/*.jar build/lib/
    chmod u+w build/lib/*.jar
    rm -f build/lib/gradle-*.jar
    rm -f build/lib/ant-*.jar
    rm -f build/lib/groovy-all-*.jar build/lib/guava-*.jar build/lib/asm-*.jar
    rm -f build/lib/httpclient-*.jar build/lib/httpcore-*.jar
    rm -f build/lib/slf4j-api-*.jar build/lib/jcl-over-slf4j-*.jar build/lib/jul-to-slf4j-*.jar
    rm -f build/lib/log4j-over-slf4j-*.jar build/lib/logback-classic-*.jar build/lib/logback-core-*.jar
    rm -f build/lib/native-platform-*.jar
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
      subprojects/base-services-groovy/src/main/groovy \
      subprojects/cli/src/main/java \
      subprojects/messaging/src/main/java \
      subprojects/native/src/main/java \
      subprojects/resources/src/main/java \
      subprojects/resources-http/src/main/java \
      subprojects/core/src/main/groovy \
      subprojects/core-impl/src/main/groovy \
      subprojects/plugin-use/src/main/java \
      subprojects/tooling-api/src/main/java \
      subprojects/wrapper/src/main/java \
      subprojects/launcher/src/main/java \
      -type f \( -name '*.groovy' -o -name '*.java' \) | sort > build/runtime-sources.txt
    find \
      subprojects/language-base/src/main/groovy \
      subprojects/language-jvm/src/main/groovy \
      subprojects/reporting/src/main/groovy \
      subprojects/diagnostics/src/main/groovy \
      subprojects/plugins/src/main/groovy \
      -type f \( -name '*.groovy' -o -name '*.java' \) | sort > build/plugins-sources.txt

    compileClasspath="$(printf '%s:' build/lib/*.jar)''${JAVA_HOME}/lib/openjdk/lib/tools.jar"
    "''$JAVA_HOME/bin/java" -noverify -Dfile.encoding=UTF-8 -Xmx2300m -classpath "$compileClasspath" \
      org.codehaus.groovy.tools.FileSystemCompiler \
      --classpath "$compileClasspath" \
      --encoding UTF-8 \
      -j \
      -d build/runtime/classes \
      @build/runtime-sources.txt

    pluginsClasspath="build/runtime/classes:$compileClasspath"
    "''$JAVA_HOME/bin/java" -noverify -Dfile.encoding=UTF-8 -Xmx1800m -classpath "$pluginsClasspath" \
      org.codehaus.groovy.tools.FileSystemCompiler \
      --classpath "$pluginsClasspath" \
      --encoding UTF-8 \
      -j \
      -d build/plugins/classes \
      @build/plugins-sources.txt

    for subproject in resources resources-http base-services base-services-groovy core core-impl launcher messaging native cli tooling-api wrapper plugin-use; do
      if [ -d "subprojects/$subproject/src/main/resources" ]; then
        cp -a "subprojects/$subproject/src/main/resources/." build/runtime/classes/
      fi
    done
    for subproject in language-base language-jvm plugins reporting diagnostics; do
      if [ -d "subprojects/$subproject/src/main/resources" ]; then
        cp -a "subprojects/$subproject/src/main/resources/." build/plugins/classes/
      fi
    done

    mkdir -p build/runtime/classes/org/gradle
    cat > build/runtime/classes/org/gradle/build-receipt.properties <<EOF
    versionNumber=${version}
    buildTimestamp=20140701000000+0000
    buildNumber=direct
    commitId=direct-bootstrap
    EOF
    printf 'plugins=gradle-plugins\n' > build/runtime/classes/gradle-plugins.properties
    mkdir -p build/runtime/classes/META-INF/services
    cat > build/runtime/classes/META-INF/services/org.gradle.internal.service.scopes.PluginServiceRegistry <<'EOF'
    org.gradle.api.internal.artifacts.DependencyServices
    org.gradle.plugin.use.internal.PluginUsePluginServiceRegistry
    org.gradle.tooling.internal.provider.ToolingServices
    EOF
    cat > build/runtime/classes/default-imports.txt <<'EOF'
    import org.gradle.*
    import org.gradle.util.*
    import org.gradle.api.*
    import org.gradle.api.artifacts.*
    import org.gradle.api.artifacts.result.*
    import org.gradle.api.artifacts.dsl.*
    import org.gradle.api.artifacts.maven.*
    import org.gradle.api.artifacts.specs.*
    import org.gradle.api.publish.*
    import org.gradle.api.publish.ivy.*
    import org.gradle.api.publish.ivy.tasks.*
    import org.gradle.api.execution.*
    import org.gradle.api.file.*
    import org.gradle.api.resources.*
    import org.gradle.api.initialization.*
    import org.gradle.api.invocation.*
    import org.gradle.api.java.archives.*
    import org.gradle.api.logging.*
    import org.gradle.api.plugins.*
    import org.gradle.api.reporting.*
    import org.gradle.language.base.*
    import org.gradle.language.jvm.*
    import org.gradle.plugins.ide.eclipse.*
    import org.gradle.plugins.ide.idea.*
    import org.gradle.plugins.jetty.*
    import org.gradle.api.plugins.quality.*
    import org.gradle.api.plugins.announce.*
    import org.gradle.api.plugins.buildcomparison.gradle.*
    import org.gradle.api.specs.*
    import org.gradle.api.tasks.*
    import org.gradle.api.tasks.bundling.*
    import org.gradle.api.tasks.diagnostics.*
    import org.gradle.api.tasks.compile.*
    import org.gradle.api.tasks.javadoc.*
    import org.gradle.api.tasks.testing.*
    import org.gradle.api.tasks.util.*
    import org.gradle.api.tasks.wrapper.*
    import org.gradle.api.tasks.scala.*
    import org.gradle.process.*
    EOF

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
    description = "Source-built Gradle ${version} bootstrap bridge";
    homepage = "https://gradle.org/";
    license = lib.licenses.asl20;
    mainProgram = "gradle";
    platforms = lib.platforms.unix;
  };
}
