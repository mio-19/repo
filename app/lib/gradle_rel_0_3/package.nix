{
  lib,
  stdenv,
  fetchFromGitHub,
  fetchurl,
  linkFarm,
  jdk8_headless,
  writableTmpDirAsHomeHook,
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
  commons_logging_1_0_3,
  jopt_simple_2_4_1,
  slf4j_api_1_4_3,
  gradle_0_3_snapshot,
}:
let
  version = "rel-0.3";
  artifacts = [
    {
      path = "org/codehaus/groovy/groovy-all/1.5.5/groovy-all-1.5.5.jar";
      hash = "sha256-2uRrDyxyGvsgPT45xG/ZoEQXrU/zqGaaY7hVg47CuZU=";
    }
    {
      path = "org/apache/ant/ant/1.7.0/ant-1.7.0.jar";
      package = "${ant_1_7_0}/ant-1.7.0.jar";
      hash = "sha256-kvcjB+dEDx41LJFvJDjSu6s//Sz3MMcTFhF60Eq63qg=";
    }
    {
      path = "org/apache/ant/ant-launcher/1.7.0/ant-launcher-1.7.0.jar";
      package = "${ant_1_7_0}/ant-launcher-1.7.0.jar";
      hash = "sha256-crPQPg19hqVlE+w43UzWq+PaZiAYm+IiqyVTUstuuko=";
    }
    {
      path = "org/apache/ant/ant-junit/1.7.0/ant-junit-1.7.0.jar";
      package = "${ant_1_7_0}/ant-junit-1.7.0.jar";
      hash = "sha256-PWfPVcDoHUEPAXHJhptZFOR+lKVTADTBwAGLlT//THg=";
    }
    {
      path = "org/apache/ant/ant-nodeps/1.7.0/ant-nodeps-1.7.0.jar";
      package = "${ant_1_7_0}/ant-nodeps-1.7.0.jar";
      hash = "sha256-HgEQTpbttkxMJbRE6OX2MIhq9nCRGMhujFrPYwFioyE=";
    }
    {
      path = "commons-cli/commons-cli/1.0/commons-cli-1.0.jar";
      package = "${commons_cli_1_0}/commons-cli-1.0.jar";
      hash = "sha256-Q/JIULe3t9ecX6ZSQYUY+99CfmArHtq+bxG4X7k+sBM=";
    }
    {
      path = "commons-io/commons-io/1.4/commons-io-1.4.jar";
      package = "${commons_io_1_4}/commons-io-1.4.jar";
      hash = "sha256-p/cTWTAHgTvwfRm9Hfn4HIbAcZ6aC7LvG5i3gxP8lA0=";
    }
    {
      path = "commons-lang/commons-lang/2.3/commons-lang-2.3.jar";
      package = "${commons_lang_2_3}/commons-lang-2.3.jar";
      hash = "sha256-BpNhxx8i+Nf71MOlaMAV4oCTJ/wuaGma62OmQXjN5W8=";
    }
    {
      path = "commons-httpclient/commons-httpclient/3.0/commons-httpclient-3.0.jar";
      package = "${commons_httpclient_3_0}/commons-httpclient-3.0.jar";
      hash = "sha256-ev0Y8w6YySv4c7ZLr+6kO0q96rpipOUOG2stAEBe9+8=";
    }
    {
      path = "commons-logging/commons-logging/1.0.3/commons-logging-1.0.3.jar";
      package = "${commons_logging_1_0_3}/commons-logging-1.0.3.jar";
      hash = "sha256-vPoCPa6oUl1tsCnqguj1jb8aBgBttlJtn5hNvyFdinU=";
    }
    {
      path = "commons-codec/commons-codec/1.2/commons-codec-1.2.jar";
      package = "${commons_codec_1_2}/commons-codec-1.2.jar";
      hash = "sha256-mJijs4V2dhKJh7l10LDwNb7PPaXPZ3Jmo01mNvK4BUI=";
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
      path = "ch/qos/logback/logback-classic/0.9.8/logback-classic-0.9.8.jar";
      hash = "sha256-NCR0VLpB4ZoaYjC8REtbr+Lz8ytGK4krMbWo7EgjjkI=";
    }
    {
      path = "ch/qos/logback/logback-core/0.9.8/logback-core-0.9.8.jar";
      hash = "sha256-1F2OvJRJ/ajW2B0AhuE5aUOqscNiz7adYUvwKnsrG3U=";
    }
    {
      path = "org/slf4j/slf4j-api/1.4.3/slf4j-api-1.4.3.jar";
      package = "${slf4j_api_1_4_3}/slf4j-api-1.4.3.jar";
      hash = "sha256-321SjPU94d9R7xVEtuDlXHsLpgS0IM9UimxjnUYfc0g=";
    }
    {
      path = "net/sf/jopt-simple/jopt-simple/2.4.1/jopt-simple-2.4.1.jar";
      package = "${jopt_simple_2_4_1}/jopt-simple-2.4.1.jar";
      hash = "sha256-18qdFFkYq/C3rfLE3lWugXQKL3XX/F6krTQC6liqdAk=";
    }
    {
      path = "org/apache/ivy/ivy/2.0.0-beta2/ivy-2.0.0-beta2.jar";
      hash = "sha256-pkDB33ILM4kjZj1d0nB3/tDEt+MrX83HoMITLSNSwWI=";
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
    rev = "REL-0.3";
    hash = "sha256-JINaw4zpPCbYv7CD88MpY6SelpaKoslkFho40cJhf6E=";
  };

  patches = [ ./gradle-rel-0.3-bootstrap.patch ];

  nativeBuildInputs = [
    jdk8_headless
    writableTmpDirAsHomeHook
  ];

  dontConfigure = true;

  buildPhase = ''
    runHook preBuild

    export JAVA_HOME=${jdk8_headless}
    mkdir -p lib

    rm -rf buildSrc/src/test src/test
    cp ${bootstrapJars}/*.jar lib/
    cp lib/ivy-2.0.0-beta2.jar lib/ivy-2.0.0.rc1_20080716132100_r677238.jar

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

    ${lib.getExe gradle_0_3_snapshot} -Duser.home="$HOME" -p "$PWD" -b build.gradle libs

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
    description = "Gradle built from upstream tag REL-0.3 using the previous bootstrap stage";
    homepage = "https://www.gradle.org/";
    sourceProvenance = with lib.sourceTypes; [ fromSource ];
    license = lib.licenses.asl20;
    mainProgram = "gradle";
    platforms = lib.platforms.unix;
  };
}
