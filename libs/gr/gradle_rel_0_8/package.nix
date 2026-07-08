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
  gradle_0_8_snapshot_20090721_3384fb22,
}:
let
  version = "0.8";
  extraArtifacts = [
    {
      path = "org/codehaus/groovy/groovy/1.6.4/groovy-1.6.4.jar";
      hash = "sha256-V+vlsQ7lTLqdm9YQq1kAwZBwhFzFmqGnjUHSwR+M3Hc=";
    }
    {
      path = "antlr/antlr/2.7.7/antlr-2.7.7.jar";
      hash = "sha256-iPvaS5Ellrn1bo4S5YDMlUus+1F3bs/d0+GPwc9W3Ew=";
    }
    {
      path = "commons-collections/commons-collections/3.2.1/commons-collections-3.2.1.jar";
      hash = "sha256-hzY6TJTqq+79i5MMsFn2a2TJ99Yyhi8j3jAS2nZgBHs=";
    }
    {
      path = "org/slf4j/jul-to-slf4j/1.5.3/jul-to-slf4j-1.5.3.jar";
      hash = "sha256-26wiKshgrArPFyhMnAoa0ZidWQmZ2P3T+h8FiBmzXQw=";
    }
    {
      path = "org/codenarc/CodeNarc/0.7/CodeNarc-0.7.jar";
      hash = "sha256-gd6ow/9nDa7z1FKIbCH4daUuL8Yya766K6ZQ9QDddLo=";
    }
  ];

  extraJars = buildMavenRepository {
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
      }) extraArtifacts
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
    tag = "REL-0.8";
    hash = "sha256-VfAtOqzRlpDyuSkSg+itiJOl7ZHAj/M7kXE2V1iboU4=";
  };

  patches = [ ./gradle-rel-0.8-direct-bootstrap.patch ];

  nativeBuildInputs = [
    jdk8_headless
  ];

  dontConfigure = true;

  buildPhase = ''
    runHook preBuild

    export JAVA_HOME=${jdk8_headless.passthru.home}
    export HOME="$TMPDIR/home"
    mkdir -p "$HOME" build/direct-core/classes build/compile-lib build/runtime-lib

    cp ${gradle_0_8_snapshot_20090721_3384fb22}/libexec/gradle/lib/*.jar build/compile-lib/
    rm -f build/compile-lib/gradle-*.jar build/compile-lib/groovy-all-*.jar
    cp ${extraJars}/*.jar build/compile-lib/

    compileClasspath="$(printf '%s:' build/compile-lib/*.jar)''${JAVA_HOME}/lib/tools.jar"

    export GRADLE_USER_HOME="$HOME/.gradle"
    "''$JAVA_HOME/bin/java" \
      -noverify \
      -Xmx1536m \
      -classpath "$compileClasspath" \
      -Dgradle.user.home="$GRADLE_USER_HOME" \
      -Duser.home="$HOME" \
      org.codehaus.groovy.tools.FileSystemCompiler \
      --classpath "$compileClasspath" \
      -j \
      -d build/direct-core/classes \
      $(find subprojects/gradle-core/src/main/groovy -type f \( -name '*.groovy' -o -name '*.java' \) | sort)

    cp -a subprojects/gradle-core/src/main/resources/. build/direct-core/classes/
    mkdir -p build/direct-core/classes/org/gradle
    cat > build/direct-core/classes/org/gradle/version.properties <<EOF
    version=${version}
    buildTime=source bootstrap
    EOF

    (
      cd build/direct-core/classes
      "''$JAVA_HOME/bin/jar" cf ../gradle-core-${version}.jar .
    )

    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall

    gradleHome="$out/libexec/gradle"
    mkdir -p "$gradleHome/lib" "$gradleHome/bin"

    cp build/direct-core/gradle-core-${version}.jar "$gradleHome/lib/gradle-core-${version}.jar"
    cp build/compile-lib/*.jar "$gradleHome/lib/"
    cp -a src/toplevel/. "$gradleHome/"

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
      -noverify \
      -classpath "${placeholder "out"}/libexec/gradle/lib/*" \
      -Dgradle.home="${placeholder "out"}/libexec/gradle" \
      org.gradle.Main \
      "''$@"
    EOF
    chmod +x "$out/bin/gradle"

    runHook postInstall
  '';

  meta = {
    description = "Gradle 0.8 core built directly from source";
    homepage = "https://www.gradle.org/";
    sourceProvenance = with lib.sourceTypes; [ fromSource ];
    license = lib.licenses.asl20;
    mainProgram = "gradle";
    platforms = lib.platforms.unix;
  };
}
