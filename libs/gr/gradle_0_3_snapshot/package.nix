{
  lib,
  stdenv,
  fetchFromGitHub,
  buildMavenRepository,
  jdk8_headless,
  writableTmpDirAsHomeHook,
  coreutils,
  findutils,
  gnugrep,
  gnused,
  which,
  commons_httpclient_3_0,
  commons_cli_1_0,
  commons_codec_1_2,
  commons_io_1_3_1,
  commons_lang_2_3,
  commons_logging_1_0_3,
  slf4j_api_1_4_3,
  gradle_0_1_snapshot,
}:
let
  version = "0.3-snapshot";
  artifacts = [
    {
      path = "org/codehaus/groovy/groovy-all/1.5.5/groovy-all-1.5.5.jar";
      hash = "sha256-2uRrDyxyGvsgPT45xG/ZoEQXrU/zqGaaY7hVg47CuZU=";
    }
    {
      path = "org/apache/ant/ant/1.7.0/ant-1.7.0.jar";
    }
    {
      path = "org/apache/ant/ant-launcher/1.7.0/ant-launcher-1.7.0.jar";
    }
    {
      path = "org/apache/ant/ant-junit/1.7.0/ant-junit-1.7.0.jar";
    }
    {
      path = "org/apache/ant/ant-nodeps/1.7.0/ant-nodeps-1.7.0.jar";
    }
    {
      path = "commons-cli/commons-cli/1.0/commons-cli-1.0.jar";
      package = "${commons_cli_1_0}/commons-cli-1.0.jar";
    }
    {
      path = "commons-io/commons-io/1.3.1/commons-io-1.3.1.jar";
      package = "${commons_io_1_3_1}/commons-io-1.3.1.jar";
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
      path = "commons-logging/commons-logging/1.0.3/commons-logging-1.0.3.jar";
      package = "${commons_logging_1_0_3}/commons-logging-1.0.3.jar";
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
    }
    {
      path = "org/apache/ivy/ivy/2.0.0-beta2/ivy-2.0.0-beta2.jar";
      hash = "sha256-pkDB33ILM4kjZj1d0nB3/tDEt+MrX83HoMITLSNSwWI=";
    }
  ];

  bootstrapJars = buildMavenRepository {
    dependencies = builtins.listToAttrs (
      map (artifact: {
        name = artifact.path;
        value = {
          layout = artifact.path;
          url = "https://repo1.maven.org/maven2/${artifact.path}";
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
    rev = "046d01a802e78cc36a6157475fc1ad1227c2bf66";
    hash = "sha256-I4UD6gwWcISFd02vOVzQ2r4Pzx2f6kwYzOgOelHdq0I=";
  };

  patches = [ ./gradle-0.3-bootstrap.patch ];

  nativeBuildInputs = [
    jdk8_headless
    writableTmpDirAsHomeHook
  ];

  dontConfigure = true;

  buildPhase = ''
    runHook preBuild

    export JAVA_HOME=${jdk8_headless.passthru.home}
    mkdir -p lib

    rm -rf buildSrc/src/test src/test
    cp ${bootstrapJars}/*.jar lib/

    ${lib.getExe gradle_0_1_snapshot} -Duser.home="$HOME" -p "$PWD" -b build.gradle libs

    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall

    gradleJar="$(find build -maxdepth 1 -type f -name '*.jar' | head -n1)"
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
    description = "Early source-bootstrapped Gradle built by Gradle 0.1";
    homepage = "https://www.gradle.org/";
    sourceProvenance = with lib.sourceTypes; [ fromSource ];
    license = lib.licenses.asl20;
    mainProgram = "gradle";
    platforms = lib.platforms.unix;
  };
}
