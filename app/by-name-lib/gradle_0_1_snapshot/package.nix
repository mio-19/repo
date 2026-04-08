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
      hash = "sha256-kvcjB+dEDx41LJFvJDjSu6s//Sz3MMcTFhF60Eq63qg=";
    }
    {
      path = "org/apache/ant/ant/1.7.0/ant-1.7.0.pom";
      hash = "sha256-fAIXQD9XogDLgNSJiSzgTqdi8qEzq+PdOEcGUUNM+vI=";
    }
    {
      path = "org/apache/ant/ant-launcher/1.7.0/ant-launcher-1.7.0.jar";
      hash = "sha256-crPQPg19hqVlE+w43UzWq+PaZiAYm+IiqyVTUstuuko=";
    }
    {
      path = "org/apache/ant/ant-launcher/1.7.0/ant-launcher-1.7.0.pom";
      hash = "sha256-0p0myykG6cOYOBvUhz7KuwTWMO9hNDXssUmoWirvyvQ=";
    }
    {
      path = "org/apache/ant/ant-junit/1.7.0/ant-junit-1.7.0.jar";
      hash = "sha256-PWfPVcDoHUEPAXHJhptZFOR+lKVTADTBwAGLlT//THg=";
    }
    {
      path = "org/apache/ant/ant-junit/1.7.0/ant-junit-1.7.0.pom";
      hash = "sha256-b6z/PljB1vSEAISg4CLGWkec6IK3KfPxU7yXZchQCQA=";
    }
    {
      path = "org/apache/ant/ant-parent/1.7.0/ant-parent-1.7.0.pom";
      hash = "sha256-GlLYNxpsvG4F7b8CZGcXEX3SNERZvulnAU8EH9zzCJM=";
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
      hash = "sha256-Q/JIULe3t9ecX6ZSQYUY+99CfmArHtq+bxG4X7k+sBM=";
    }
    {
      path = "commons-cli/commons-cli/1.0/commons-cli-1.0.pom";
      hash = "sha256-l+5A9OgMpezCAWL06X7hrf6sG0W6iLkj1aUh5IfJxAc=";
    }
    {
      path = "commons-io/commons-io/1.3.1/commons-io-1.3.1.jar";
      hash = "sha256-MwcxndwiHxsj6KFEWu8Q0tIwjg7EaXez8Xy7FcDvM1s=";
    }
    {
      path = "commons-io/commons-io/1.3.1/commons-io-1.3.1.pom";
      hash = "sha256-B+c8qNvJzOFOLxOc0fT8CeaBQO4avZHJClC1Wl64L30=";
    }
    {
      path = "commons-lang/commons-lang/2.3/commons-lang-2.3.jar";
      hash = "sha256-BpNhxx8i+Nf71MOlaMAV4oCTJ/wuaGma62OmQXjN5W8=";
    }
    {
      path = "commons-lang/commons-lang/2.3/commons-lang-2.3.pom";
      hash = "sha256-VijV6y6CDeec+j8alwMbeBMlmOm789QZN2V9326cYGQ=";
    }
    {
      path = "commons-httpclient/commons-httpclient/3.0/commons-httpclient-3.0.jar";
      hash = "sha256-ev0Y8w6YySv4c7ZLr+6kO0q96rpipOUOG2stAEBe9+8=";
    }
    {
      path = "commons-httpclient/commons-httpclient/3.0/commons-httpclient-3.0.pom";
      hash = "sha256-84yodRd/RBCO4n6hhqyiSP8FRQiIRp0eev78xMeSe5A=";
    }
    {
      path = "commons-logging/commons-logging/1.0.3/commons-logging-1.0.3.jar";
      hash = "sha256-vPoCPa6oUl1tsCnqguj1jb8aBgBttlJtn5hNvyFdinU=";
    }
    {
      path = "commons-logging/commons-logging/1.0.3/commons-logging-1.0.3.pom";
      hash = "sha256-jCPG6S8d9/WLRVzSyqAJ3Mh6L+ZJdubORhUi5jWupB4=";
    }
    {
      path = "commons-codec/commons-codec/1.2/commons-codec-1.2.jar";
      hash = "sha256-mJijs4V2dhKJh7l10LDwNb7PPaXPZ3Jmo01mNvK4BUI=";
    }
    {
      path = "commons-codec/commons-codec/1.2/commons-codec-1.2.pom";
      hash = "sha256-KNbAiTVUh/0ulz4JGhUnJ6wnrSssHsnLz5FqEPyGMUg=";
    }
    {
      path = "junit/junit/3.8.1/junit-3.8.1.jar";
      hash = "sha256-tY5FlQnhkL7XN/NZK8GVBIUyKEbPEOeN7R0GUVMBLXA=";
    }
    {
      path = "junit/junit/3.8.1/junit-3.8.1.pom";
      hash = "sha256-5o8zND2DI5jzyKp4r82AjVa3wQIN5NOtjOR5CQle6QQ=";
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
      hash = "sha256-321SjPU94d9R7xVEtuDlXHsLpgS0IM9UimxjnUYfc0g=";
    }
    {
      path = "org/slf4j/slf4j-api/1.4.3/slf4j-api-1.4.3.pom";
      hash = "sha256-rIUYuIYos+IHj7WxIGOvbfgq4HGU1AlmA6rcvy8dlrI=";
    }
    {
      path = "org/slf4j/slf4j-parent/1.4.3/slf4j-parent-1.4.3.pom";
      hash = "sha256-PuzZ0E3tNbkbSLkQhEphVCLYKTJqhUB7fm/3JPJPHSI=";
    }
  ];

  mavenRepo = linkFarm "gradle-${version}-maven-repo" (
    map (artifact: {
      name = artifact.path;
      path = fetchurl {
        url = "https://repo1.maven.org/maven2/${artifact.path}";
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
    rev = "e09125febb2abd4d5eb70714ff68cdc76ee7dc45";
    hash = "sha256-PYGUYrXbvdGgY6kLGcwWYH3C2QiCiyOe4NJnJiKvHFU=";
  };

  patches = [ ./gradle-0.1-bootstrap.patch ];

  nativeBuildInputs = [
    ant
    jdk8_headless
    makeWrapper
  ];

  dontConfigure = true;

  buildPhase = ''
    runHook preBuild

    export JAVA_HOME=${jdk8_headless}
    export HOME="$TMPDIR/home"
    export mavenRepo="${mavenRepo}"
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
      --set-default JAVA_HOME ${jdk8_headless} \
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
