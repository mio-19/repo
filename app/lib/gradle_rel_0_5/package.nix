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
  ant_1_7_0,
  commons_httpclient_3_0,
  commons_cli_1_0,
  commons_codec_1_2,
  commons_io_1_4,
  commons_lang_2_3,
  jopt_simple_2_4_1,
  servlet_api_2_5,
  slf4j_1_5_3,
  gradle_rel_0_4,
}:
let
  version = "rel-0.5";
  artifacts = [
    {
      path = "org/codehaus/groovy/groovy-all/1.5.6/groovy-all-1.5.6.jar";
      hash = "sha256-vKxmqYQPMCrrLtr5uNNoMzIEIzS2rr8imfDM8Yj2Cls=";
    }
    {
      path = "org/apache/ant/ant/1.7.0/ant-1.7.0.jar";
      package = "${ant_1_7_0}/ant-1.7.0.jar";
    }
    {
      path = "org/apache/ant/ant-launcher/1.7.0/ant-launcher-1.7.0.jar";
      package = "${ant_1_7_0}/ant-launcher-1.7.0.jar";
    }
    {
      path = "org/apache/ant/ant-junit/1.7.0/ant-junit-1.7.0.jar";
      package = "${ant_1_7_0}/ant-junit-1.7.0.jar";
    }
    {
      path = "org/apache/ant/ant-nodeps/1.7.0/ant-nodeps-1.7.0.jar";
      package = "${ant_1_7_0}/ant-nodeps-1.7.0.jar";
    }
    {
      path = "commons-cli/commons-cli/1.0/commons-cli-1.0.jar";
      package = "${commons_cli_1_0}/commons-cli-1.0.jar";
    }
    {
      path = "commons-io/commons-io/1.4/commons-io-1.4.jar";
      package = "${commons_io_1_4}/commons-io-1.4.jar";
    }
    {
      path = "commons-lang/commons-lang/2.3/commons-lang-2.3.jar";
      package = "${commons_lang_2_3}/commons-lang-2.3.jar";
    }
    {
      path = "commons-httpclient/commons-httpclient/3.0/commons-httpclient-3.0.jar";
      package = "${commons_httpclient_3_0}/commons-httpclient-3.0.jar";
    }
    {
      path = "commons-codec/commons-codec/1.2/commons-codec-1.2.jar";
      package = "${commons_codec_1_2}/commons-codec-1.2.jar";
    }
    {
      path = "junit/junit/4.4/junit-4.4.jar";
      hash = "sha256-D2uM7WfX5ywVgA53u+wem1bmFLNC6+v9SQtCaOHP0P8=";
    }
    {
      path = "slide/webdavlib/2.0/webdavlib-2.0.jar";
      hash = "sha256-CijngVokZPOPfIC2Hd0T4EZaeHMoUozMIFLvapG6Tyc=";
    }
    {
      path = "ch/qos/logback/logback-classic/0.9.9/logback-classic-0.9.9.jar";
      hash = "sha256-sZ0cKny7+I1sxzxuPsWjA/3jh/zX8u4N5EZrRioyMrE=";
    }
    {
      path = "ch/qos/logback/logback-core/0.9.9/logback-core-0.9.9.jar";
      hash = "sha256-9uxzDnLF9PA8rYJ7hGScRWcRR8fL3v9iYHHzFETwoTY=";
    }
    {
      path = "org/slf4j/slf4j-api/1.5.3/slf4j-api-1.5.3.jar";
      package = "${slf4j_1_5_3}/slf4j-api-1.5.3.jar";
    }
    {
      path = "org/slf4j/jcl-over-slf4j/1.5.3/jcl-over-slf4j-1.5.3.jar";
      package = "${slf4j_1_5_3}/jcl-over-slf4j-1.5.3.jar";
    }
    {
      path = "net/sf/jopt-simple/jopt-simple/2.4.1/jopt-simple-2.4.1.jar";
      package = "${jopt_simple_2_4_1}/jopt-simple-2.4.1.jar";
    }
    {
      path = "org/apache/ivy/ivy/2.0.0-rc2/ivy-2.0.0-rc2.jar";
      hash = "sha256-U6nTHEd3EiWAPKkZaJit88ptL8pIGRCiipkes26+Kvc=";
    }
    {
      path = "dom4j/dom4j/1.6.1/dom4j-1.6.1.jar";
      hash = "sha256-WTVS/+o8WCPGYCR4tQAqfFJf2QSjxE8avkBlwi7frHM=";
    }
    {
      path = "jaxen/jaxen/1.1/jaxen-1.1.jar";
      hash = "sha256-SWdVeYIksMjwxEcRd4UvG+8palJKLfd2XvnfUFTlrp8=";
    }
    {
      path = "org/mortbay/jetty/jetty/6.1.14/jetty-6.1.14.jar";
      hash = "sha256-IwGVcKiM3lf3z572YuVvZssXnc9+KMvg0WKedk0Iw0M=";
    }
    {
      path = "org/mortbay/jetty/jetty-naming/6.1.14/jetty-naming-6.1.14.jar";
      hash = "sha256-YifLBTUXj61rNyi1Bd2m4u5zUQZj/fA1albdsJCWlWw=";
    }
    {
      path = "org/mortbay/jetty/jetty-plus/6.1.14/jetty-plus-6.1.14.jar";
      hash = "sha256-/TzONrhfY5XOE4Fjz/hqYAoAg4c0aL+CrDHPOZo/TJ8=";
    }
    {
      path = "org/mortbay/jetty/jetty-util/6.1.14/jetty-util-6.1.14.jar";
      hash = "sha256-8mY5/R7P2Dpm+dilkyQvpavXW7R2TP2siLQHmpP+Mvk=";
    }
    {
      path = "javax/servlet/servlet-api/2.5/servlet-api-2.5.jar";
      package = "${servlet_api_2_5}/servlet-api-2.5.jar";
    }
    {
      path = "biz/aQute/bndlib/0.0.255/bndlib-0.0.255.jar";
      hash = "sha256-cR7DDjyjqSL4AdusnJGRavd1XsWHLUezEGwMUXKL6yU=";
    }
    {
      path = "org/apache/maven/maven-ant-tasks/2.0.9/maven-ant-tasks-2.0.9.jar";
      hash = "sha256-SCKPuTSA6sOHGTqyTSx7dIrMZj8Tj8dhGoKuFRN2xbY=";
    }
  ];

  bootstrapJars = linkFarm "gradle-${version}-bootstrap-jars" (
    map (artifact: {
      name = baseNameOf artifact.path;
      path =
        artifact.package or (fetchurl {
          url = "https://repo1.maven.org/maven2/${artifact.path}";
          hash = artifact.hash;
        });
    }) artifacts
  );
in
stdenv.mkDerivation {
  pname = "gradle";
  inherit version;

  src = fetchFromGitHub {
    owner = "gradle";
    repo = "gradle";
    tag = "REL-0.5";
    hash = "sha256-avnPA03dL0OQxDwoZ9vcwDw4TiQQ5M1EsUb1dTjJ658=";
  };

  patches = [ ./gradle-rel-0.5-bootstrap.patch ];

  nativeBuildInputs = [
    jdk8_headless
  ];

  dontConfigure = true;

  buildPhase = ''
    runHook preBuild

    export JAVA_HOME=${jdk8_headless}
    export HOME="$TMPDIR/home"
    mkdir -p "$HOME" lib

    rm -rf buildSrc/src/test src/test
    cp ${bootstrapJars}/*.jar lib/

    mkdir -p bootstrap-support/src/org/gradle/api/tasks bootstrap-support/classes
    cat > bootstrap-support/src/org/gradle/api/tasks/StopActionException.java <<'EOF'
    package org.gradle.api.tasks;
    public class StopActionException extends RuntimeException {
      public StopActionException() { super(); }
      public StopActionException(String message) { super(message); }
    }
    EOF
    "$JAVA_HOME/bin/javac" -d bootstrap-support/classes bootstrap-support/src/org/gradle/api/tasks/StopActionException.java
    "$JAVA_HOME/bin/jar" cf bootstrap-support/stop-action-support.jar -C bootstrap-support/classes .

    "''$JAVA_HOME/bin/java" \
      -classpath "bootstrap-support/stop-action-support.jar:${gradle_rel_0_4}/libexec/gradle/lib/*" \
      -Dgradle.home="${gradle_rel_0_4}/libexec/gradle" \
      org.gradle.Main \
      -p "$PWD" \
      -b build.gradle \
      libs

    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall

    gradleJar="$(find build -maxdepth 1 -type f -name '*.jar' ! -name '*wrapper*' | head -n1)"
    test -n "$gradleJar"
    test -f "$gradleJar"

    gradleHome="$out/libexec/gradle"
    mkdir -p "$gradleHome/lib" "$gradleHome/bin"

    cp "$gradleJar" "$gradleHome/lib/"
    cp lib/*.jar "$gradleHome/lib/"
    cp -r src/toplevel/. "$gradleHome/"

    mkdir -p "$out/bin"
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
      -classpath "${placeholder "out"}/libexec/gradle/lib/*" \
      -Dgradle.home="${placeholder "out"}/libexec/gradle" \
      org.gradle.Main \
      bootstrap \
      "''$@"
    EOF
    chmod +x "$out/bin/gradle"

    runHook postInstall
  '';

  meta = {
    description = "Gradle built from upstream tag REL-0.5 using the previous bootstrap stage";
    homepage = "https://www.gradle.org/";
    sourceProvenance = with lib.sourceTypes; [ fromSource ];
    license = lib.licenses.asl20;
    mainProgram = "gradle";
    platforms = lib.platforms.unix;
  };
}
