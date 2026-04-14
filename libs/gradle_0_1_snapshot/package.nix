# read https://discuss.gradle.org/t/building-gradle-from-pure-source-without-any-bootstrap-binaries/19398/7
{
  lib,
  stdenv,
  fetchFromGitHub,
  fetchurl,
  linkFarm,
  ant,
  jdk8_headless,
  makeWrapper,
  coreutils,
  findutils,
  gnugrep,
  gnused,
  which,
  buildMavenRepository,
  commons_httpclient_3_0,
  commons_cli_1_0,
  commons_codec_1_2,
  commons_io_1_3_1,
  commons_lang_2_3,
  commons_logging_1_0_3,
  junit_3_8_1,
  slf4j_api_1_4_3,
  writableTmpDirAsHomeHook,
}:
let
  version = "0.1-snapshot";
  artifacts = [
    {
      path = "org/codehaus/groovy/groovy-all/1.5.5/groovy-all-1.5.5.jar";
      hash = "sha256-2uRrDyxyGvsgPT45xG/ZoEQXrU/zqGaaY7hVg47CuZU=";
    }
    {
      path = "org/codehaus/groovy/groovy-all/1.5.5/groovy-all-1.5.5.pom";
      hash = "sha256-X+Jahn6OufTKjXpbOrxQXoMAn5ylXoVpdxeemAMrSVw=";
    }
    {
      path = "org/apache/ant/ant/1.7.0/ant-1.7.0.jar";
    }
    {
      path = "org/apache/ant/ant/1.7.0/ant-1.7.0.pom";
    }
    {
      path = "org/apache/ant/ant-launcher/1.7.0/ant-launcher-1.7.0.jar";
    }
    {
      path = "org/apache/ant/ant-launcher/1.7.0/ant-launcher-1.7.0.pom";
    }
    {
      path = "org/apache/ant/ant-junit/1.7.0/ant-junit-1.7.0.jar";
    }
    {
      path = "org/apache/ant/ant-junit/1.7.0/ant-junit-1.7.0.pom";
    }
    {
      path = "org/apache/ant/ant-parent/1.7.0/ant-parent-1.7.0.pom";
    }
    {
      path = "org/apache/ivy/ivy/2.0.0-beta2/ivy-2.0.0-beta2.jar";
      hash = "sha256-pkDB33ILM4kjZj1d0nB3/tDEt+MrX83HoMITLSNSwWI=";
    }
    {
      path = "org/apache/ivy/ivy/2.0.0-beta2/ivy-2.0.0-beta2.pom";
      hash = "sha256-Xi9N8LQGy2ign8b07GjfVyvO+bXjhVsVJGH4m+5xsoU=";
    }
    {
      path = "commons-cli/commons-cli/1.0/commons-cli-1.0.jar";
      package = "${commons_cli_1_0}/commons-cli-1.0.jar";
    }
    {
      path = "commons-cli/commons-cli/1.0/commons-cli-1.0.pom";
      package = "${commons_cli_1_0}/commons-cli-1.0.pom";
    }
    {
      path = "commons-io/commons-io/1.3.1/commons-io-1.3.1.jar";
      package = "${commons_io_1_3_1}/commons-io-1.3.1.jar";
    }
    {
      path = "commons-io/commons-io/1.3.1/commons-io-1.3.1.pom";
      package = "${commons_io_1_3_1}/commons-io-1.3.1.pom";
    }
    {
      path = "commons-lang/commons-lang/2.3/commons-lang-2.3.jar";
      package = "${commons_lang_2_3}/commons-lang-2.3.jar";
    }
    {
      path = "commons-lang/commons-lang/2.3/commons-lang-2.3.pom";
      package = "${commons_lang_2_3}/commons-lang-2.3.pom";
    }
    {
      path = "commons-httpclient/commons-httpclient/3.0/commons-httpclient-3.0.jar";
      package = "${commons_httpclient_3_0}/commons-httpclient-3.0.jar";
    }
    {
      path = "commons-httpclient/commons-httpclient/3.0/commons-httpclient-3.0.pom";
      package = "${commons_httpclient_3_0}/commons-httpclient-3.0.pom";
    }
    {
      path = "commons-logging/commons-logging/1.0.3/commons-logging-1.0.3.jar";
      package = "${commons_logging_1_0_3}/commons-logging-1.0.3.jar";
    }
    {
      path = "commons-logging/commons-logging/1.0.3/commons-logging-1.0.3.pom";
      package = "${commons_logging_1_0_3}/commons-logging-1.0.3.pom";
    }
    {
      path = "commons-codec/commons-codec/1.2/commons-codec-1.2.jar";
      package = "${commons_codec_1_2}/commons-codec-1.2.jar";
    }
    {
      path = "commons-codec/commons-codec/1.2/commons-codec-1.2.pom";
      package = "${commons_codec_1_2}/commons-codec-1.2.pom";
    }
    {
      path = "junit/junit/3.8.1/junit-3.8.1.jar";
      package = "${junit_3_8_1}/junit-3.8.1.jar";
    }
    {
      path = "junit/junit/3.8.1/junit-3.8.1.pom";
      package = "${junit_3_8_1}/junit-3.8.1.pom";
    }
    {
      path = "junit/junit/4.4/junit-4.4.jar";
      hash = "sha256-D2uM7WfX5ywVgA53u+wem1bmFLNC6+v9SQtCaOHP0P8=";
    }
    {
      path = "junit/junit/4.4/junit-4.4.pom";
      hash = "sha256-kFgS0em5SGPIUUzkB74AUgHndPbrOv6x4P+shypYWcA=";
    }
    {
      path = "slide/webdavlib/2.0/webdavlib-2.0.jar";
      hash = "sha256-CijngVokZPOPfIC2Hd0T4EZaeHMoUozMIFLvapG6Tyc=";
    }
    {
      path = "slide/webdavlib/2.0/webdavlib-2.0.pom";
      hash = "sha256-Nw43IuffD5KHpz7+HyQWBtfvOaVA7WmHsYCSslW0EY4=";
    }
    {
      path = "ch/qos/logback/logback-classic/0.9.8/logback-classic-0.9.8.jar";
      hash = "sha256-NCR0VLpB4ZoaYjC8REtbr+Lz8ytGK4krMbWo7EgjjkI=";
    }
    {
      path = "ch/qos/logback/logback-classic/0.9.8/logback-classic-0.9.8.pom";
      hash = "sha256-U99dsUun+5nyKRAUGmjVt+eNn/V5zCnXcN/AH4a7zso=";
    }
    {
      path = "ch/qos/logback/logback-core/0.9.8/logback-core-0.9.8.jar";
      hash = "sha256-1F2OvJRJ/ajW2B0AhuE5aUOqscNiz7adYUvwKnsrG3U=";
    }
    {
      path = "ch/qos/logback/logback-core/0.9.8/logback-core-0.9.8.pom";
      hash = "sha256-FSQWqT+UIjAT/yrnDtj/GhjQ7pF5MKXYYNag9rabb+I=";
    }
    {
      path = "ch/qos/logback/logback-parent/0.9.8/logback-parent-0.9.8.pom";
      hash = "sha256-9NG7H5xVI5TYhZOFHEoDBGy2pCgJNmyOgw/XAJy3HWg=";
    }
    {
      path = "org/slf4j/slf4j-api/1.4.3/slf4j-api-1.4.3.jar";
      package = "${slf4j_api_1_4_3}/slf4j-api-1.4.3.jar";
    }
    {
      path = "org/slf4j/slf4j-api/1.4.3/slf4j-api-1.4.3.pom";
      package = "${slf4j_api_1_4_3}/slf4j-api-1.4.3.pom";
    }
    {
      path = "org/slf4j/slf4j-parent/1.4.3/slf4j-parent-1.4.3.pom";
      package = "${slf4j_api_1_4_3}/slf4j-parent-1.4.3.pom";
    }
  ];

  mavenRepo = buildMavenRepository {
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
  };

  postfix = if stdenv.isDarwin then "" else "/lib/openjdk";
in
stdenv.mkDerivation {
  pname = "gradle";
  inherit version;

  src = fetchFromGitHub {
    owner = "gradle";
    repo = "gradle";
    rev = "e09125febb2abd4d5eb70714ff68cdc76ee7dc45";
    hash = "sha256-PYGUYrXbvdGgY6kLGcwWYH3C2QiCiyOe4NJnJiKvHFU=";
  };

  patches = [ ./gradle-0.1-bootstrap.patch ];

  nativeBuildInputs = [
    ant
    jdk8_headless
    makeWrapper
    writableTmpDirAsHomeHook
  ];

  dontConfigure = true;

  buildPhase = ''
    runHook preBuild

    export JAVA_HOME=${jdk8_headless.passthru.home}${postfix}
    export CLASSPATH=${jdk8_headless}${postfix}/lib/tools.jar
    export mavenRepo="${mavenRepo}"
    export ANT_OPTS=-Divy.default.ivy.user.dir="$HOME/.ivy2"
    mkdir -p "$HOME/.ivy2/local" ivy src/samples

    cp ${mavenRepo}/org/apache/ivy/ivy/2.0.0-beta2/ivy-2.0.0-beta2.jar \
      ivy/ivy-2.0.0.beta2_20080305165542.jar

    substituteAll ${./ivysettings.xml.in} ivysettings.xml

    ant dist -Dtest.skip=true -Dintegtest.skip=true

    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall

    dist_dir="target/dist/gradle-${version}"
    test -d "$dist_dir"

    mkdir -p "$out/libexec"
    cp -a "$dist_dir" "$out/libexec/gradle"
    patchShebangs "$out/libexec/gradle/bin"

    mkdir -p "$out/bin"
    makeWrapper "$out/libexec/gradle/bin/gradle" "$out/bin/gradle" \
      --set-default JAVA_HOME ${jdk8_headless}${postfix} \
      --suffix PATH : ${
        lib.makeBinPath [
          coreutils
          findutils
          gnugrep
          gnused
          which
        ]
      }

    runHook postInstall
  '';

  passthru.jdk = jdk8_headless;

  meta = with lib; {
    description = "Gradle 0.1 snapshot bootstrapped from source with Ant";
    homepage = "https://github.com/gradle/gradle";
    license = licenses.asl20;
    mainProgram = "gradle";
    platforms = platforms.unix;
  };
}
