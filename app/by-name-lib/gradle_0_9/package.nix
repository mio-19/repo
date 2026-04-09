{
  lib,
  stdenv,
  fetchFromGitHub,
  fetchurl,
  linkFarm,
  jdk8_headless,
  coreutils,
  findutils,
  gnugrep,
  gnused,
  which,
  gradle_rel_0_8,
}:
let
  version = "0.9";
  artifacts = [
    {
      path = "org/codehaus/groovy/groovy-all/1.7.6/groovy-all-1.7.6.jar";
      hash = "sha256-8fZUVuhOUMzxiq+G8n6RY3BkLd6QcX8tmHpnCDmtKMk=";
    }
    {
      path = "asm/asm-all/3.2/asm-all-3.2.jar";
      hash = "sha256-zZxZThvYeT9zGAZ98lz8dm4tmAmsIAxc1L0NqjjSgU4=";
    }
    {
      path = "org/apache/ant/ant/1.8.1/ant-1.8.1.jar";
      hash = "sha256-GgK6/7qbr9yK/Qs5my+1qF3Ch+uFFLrZWJZawABaCWA=";
    }
    {
      path = "org/apache/ant/ant-launcher/1.8.1/ant-launcher-1.8.1.jar";
      hash = "sha256-KM+3ACDf255OJhzu0WxDrtcVwdETkOPdvs2h5UglMWg=";
    }
    {
      path = "org/apache/ant/ant-nodeps/1.8.1/ant-nodeps-1.8.1.jar";
      hash = "sha256-quB6V5siMtWNWcKMSYg5+GuE14nxR5lv+ETHrWzGfZo=";
    }
    {
      path = "org/apache/ivy/ivy/2.2.0/ivy-2.2.0.jar";
      hash = "sha256-nQpWAmaAmZmGyjPVPRLW8o97/148nm4MZjOjZ3ygDxg=";
    }
    {
      path = "com/jcraft/jsch/0.1.42/jsch-0.1.42.jar";
      hash = "sha256-dCl1UK7MO1Zu4Z5Jvvuc1J4jJsnY1xrVBxusxlW3YNw=";
    }
    {
      path = "com/jcraft/jzlib/1.0.7/jzlib-1.0.7.jar";
      hash = "sha256-Fr0OCCwSviinb/JuNWIZJGzVe+9SkOUARedaPPsSCBw=";
    }
    {
      path = "commons-lang/commons-lang/2.5/commons-lang-2.5.jar";
      hash = "sha256-pk4Mc5iP741bc/wp0QWjpuLcXZuQqU/KBlzSQ53FZZA=";
    }
    {
      path = "com/google/collections/google-collections/1.0/google-collections-1.0.jar";
      hash = "sha256-gbjWOK8Ag8S4dwmdVqoP7nFEhc0qzhtqCcq4Z8rbN10=";
    }
    {
      path = "org/slf4j/slf4j-api/1.6.1/slf4j-api-1.6.1.jar";
      hash = "sha256-2EnRF/w3mIOMbNQttqfs9tmuBQw5l0F7jk4lHlkrHT4=";
    }
    {
      path = "org/slf4j/jcl-over-slf4j/1.6.1/jcl-over-slf4j-1.6.1.jar";
      hash = "sha256-87dg+3JgUGnwyy80dj777H4o1MAT2RUR56rXEA6+lEg=";
    }
    {
      path = "org/slf4j/jul-to-slf4j/1.6.1/jul-to-slf4j-1.6.1.jar";
      hash = "sha256-EkcLDKLscHpcrH2z/E5P9NokrgcyX6I0konSvDJ6y8U=";
    }
    {
      path = "org/slf4j/log4j-over-slf4j/1.6.1/log4j-over-slf4j-1.6.1.jar";
      hash = "sha256-8LOsOs73cFeS8wdWroqQLWBc2oRxqugzHm3cG0N5NBM=";
    }
    {
      path = "ch/qos/logback/logback-classic/0.9.24/logback-classic-0.9.24.jar";
      hash = "sha256-gPbHxhMEesgE//aqtiXsiqssrmtvweTaX4sn2LLxcSY=";
    }
    {
      path = "ch/qos/logback/logback-core/0.9.24/logback-core-0.9.24.jar";
      hash = "sha256-KbFKm2/gWu5ee4VvqaHw4hpxs+Lj2Tw2QXB/a46/BUk=";
    }
    {
      path = "org/apache/maven/maven-ant-tasks/2.1.1/maven-ant-tasks-2.1.1.jar";
      hash = "sha256-uIkbSpCsonk604WrVyFvUcSHnGq36Sc1T0B7RlEMq1E=";
    }
    {
      path = "org/fusesource/jansi/jansi/1.2.1/jansi-1.2.1.jar";
      hash = "sha256-07/+9DtjINU9OmgEyEtrSg4TcMP6OenA0SSrZVWLuRQ=";
    }
    {
      path = "org/jruby/ext/posix/jna-posix/1.0.3/jna-posix-1.0.3.jar";
      hash = "sha256-UuYkLxUMg8hiQBG3ozxG5jObK/ATqlWdcVi8T6nB6mA=";
    }
    {
      path = "net/java/dev/jna/jna/3.2.2/jna-3.2.2.jar";
      hash = "sha256-/o8Xb7+sDBzy+M19M2EPp8VI9VFy0C0gLjJwF02p2HU=";
    }
    {
      path = "org/codehaus/plexus/plexus-component-annotations/1.5.2/plexus-component-annotations-1.5.2.jar";
      hash = "sha256-7RBipCkXH1H9eR6V3OkkNiEVwM/pBti+9GsuELZBuO0=";
    }
    {
      path = "org/sonatype/pmaven/pmaven-common/0.8-20100325/pmaven-common-0.8-20100325.jar";
      url = "https://repo.gradle.org/gradle/libs/org/sonatype/pmaven/pmaven-common/0.8-20100325/pmaven-common-0.8-20100325.jar";
      hash = "sha256-EpMGq82zN81T5xCq2vqiJvAXmX5ryBwstQ3rAJFsqNg=";
    }
    {
      path = "org/sonatype/pmaven/pmaven-groovy/0.8-20100325/pmaven-groovy-0.8-20100325.jar";
      url = "https://repo.gradle.org/gradle/libs/org/sonatype/pmaven/pmaven-groovy/0.8-20100325/pmaven-groovy-0.8-20100325.jar";
      hash = "sha256-h4kaNz0Hn9Nw6Fmx9b0Fedi0po5RX6i7rpEwHCj0jVc=";
    }
  ];

  artifactJars = linkFarm "gradle-${version}-jars" (
    map (artifact: {
      name = baseNameOf artifact.path;
      path = fetchurl {
        url = artifact.url or "https://repo1.maven.org/maven2/${artifact.path}";
        hash = artifact.hash;
      };
    }) artifacts
  );
in
stdenv.mkDerivation {
  pname = "gradle";
  inherit version;

  src = fetchFromGitHub {
    owner = "gradle";
    repo = "gradle";
    tag = "v0.9";
    hash = "sha256-J38m1DTIKj7+eqEthFTbkaUYTW9ozz/9Hc+OOh5yBfQ=";
  };

  nativeBuildInputs = [ jdk8_headless ];

  dontConfigure = true;

  buildPhase = ''
    runHook preBuild

    export JAVA_HOME=${jdk8_headless}
    export HOME="$TMPDIR/home"
    mkdir -p "$HOME" build/lib build/core/classes build/launcher/classes build/launcher-stub

    cp ${gradle_rel_0_8}/libexec/gradle/lib/*.jar build/lib/
    rm -f build/lib/gradle-core-*.jar build/lib/groovy-*.jar build/lib/groovy-all-*.jar
    rm -f build/lib/ant-*.jar build/lib/ivy-*.jar build/lib/slf4j-*.jar
    rm -f build/lib/jcl-over-slf4j-*.jar build/lib/jul-to-slf4j-*.jar build/lib/log4j-over-slf4j-*.jar
    rm -f build/lib/logback-*.jar build/lib/asm-*.jar build/lib/jsch-*.jar build/lib/commons-lang-*.jar
    rm -f build/lib/maven-ant-tasks-*.jar
    cp ${artifactJars}/*.jar build/lib/

    compileClasspath="$(printf '%s:' build/lib/*.jar)''${JAVA_HOME}/lib/tools.jar"

    "''$JAVA_HOME/bin/java" -noverify -Xmx1536m -classpath "$compileClasspath" \
      org.codehaus.groovy.tools.FileSystemCompiler \
      --classpath "$compileClasspath" \
      -j \
      -d build/core/classes \
      $(find subprojects/gradle-core/src/main/groovy -type f \( -name '*.groovy' -o -name '*.java' \) | sort)

    cp -a subprojects/gradle-core/src/main/resources/. build/core/classes/
    chmod -R u+w build/core/classes
    mkdir -p build/core/classes/org/gradle
    cat > build/core/classes/org/gradle/version.properties <<EOF
    version=${version}
    buildTime=source bootstrap
    EOF

    mkdir -p build/launcher-stub/org/gradle/gradleplugin/userinterface/swing/standalone
    cat > build/launcher-stub/org/gradle/gradleplugin/userinterface/swing/standalone/BlockingApplication.java <<'EOF'
    package org.gradle.gradleplugin.userinterface.swing.standalone;

    public class BlockingApplication {
        public static void launchAndBlock() {
            throw new UnsupportedOperationException("Gradle GUI is not part of this bootstrap build");
        }
    }
    EOF

    launcherClasspath="build/core/classes:$compileClasspath"
    "''$JAVA_HOME/bin/javac" \
      -cp "$launcherClasspath" \
      -d build/launcher/classes \
      build/launcher-stub/org/gradle/gradleplugin/userinterface/swing/standalone/BlockingApplication.java \
      $(find subprojects/gradle-launcher/src/main/java -type f -name '*.java' | sort)

    (
      cd build/core/classes
      "''$JAVA_HOME/bin/jar" cf ../gradle-core-${version}.jar .
    )
    (
      cd build/launcher/classes
      "''$JAVA_HOME/bin/jar" cf ../gradle-launcher-${version}.jar .
    )

    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall

    gradleHome="$out/libexec/gradle"
    mkdir -p "$gradleHome/lib" "$out/bin"

    cp build/core/gradle-core-${version}.jar "$gradleHome/lib/"
    cp build/launcher/gradle-launcher-${version}.jar "$gradleHome/lib/"
    cp build/lib/*.jar "$gradleHome/lib/"
    cp -a src/toplevel/. "$gradleHome/"

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
      -classpath "${placeholder "out"}/libexec/gradle/lib/*" \
      -Dgradle.home="${placeholder "out"}/libexec/gradle" \
      org.gradle.launcher.Main \
      "''$@"
    EOF
    chmod +x "$out/bin/gradle"

    runHook postInstall
  '';

  meta = {
    description = "Gradle 0.9 core and launcher built directly from source";
    homepage = "https://www.gradle.org/";
    sourceProvenance = with lib.sourceTypes; [ fromSource ];
    license = lib.licenses.asl20;
    mainProgram = "gradle";
    platforms = lib.platforms.unix;
  };
}
