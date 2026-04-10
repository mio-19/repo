{
  callPackage,
  lib,
  stdenv,
  fetchFromGitHub,
  fetchurl,
  gradle-packages,
  gradle_2_14_1,
  jdk8_headless,
  coreutils,
  findutils,
  gnugrep,
  gnused,
  which,
  unzip,
}:
let
  version = "3.0-milestone-1";
  gradleModules = [
    "gradle-base-services"
    "gradle-base-services-groovy"
    "gradle-cli"
    "gradle-core"
    "gradle-docs"
    "gradle-installation-beacon"
    "gradle-jvm-services"
    "gradle-launcher"
    "gradle-logging"
    "gradle-messaging"
    "gradle-model-core"
    "gradle-model-groovy"
    "gradle-native"
    "gradle-open-api"
    "gradle-process-services"
    "gradle-resources"
    "gradle-tooling-api"
    "gradle-ui"
    "gradle-wrapper"
  ];
  pluginModules = [
    "gradle-announce"
    "gradle-antlr"
    "gradle-build-comparison"
    "gradle-build-init"
    "gradle-code-quality"
    "gradle-dependency-management"
    "gradle-diagnostics"
    "gradle-ear"
    "gradle-ide"
    "gradle-ide-native"
    "gradle-ide-play"
    "gradle-ivy"
    "gradle-jacoco"
    "gradle-javascript"
    "gradle-jetty"
    "gradle-language-groovy"
    "gradle-language-java"
    "gradle-language-jvm"
    "gradle-language-native"
    "gradle-language-scala"
    "gradle-maven"
    "gradle-osgi"
    "gradle-platform-base"
    "gradle-platform-jvm"
    "gradle-platform-native"
    "gradle-platform-play"
    "gradle-plugin-development"
    "gradle-plugin-use"
    "gradle-plugins"
    "gradle-publish"
    "gradle-reporting"
    "gradle-resources-http"
    "gradle-resources-s3"
    "gradle-resources-sftp"
    "gradle-scala"
    "gradle-signing"
    "gradle-test-kit"
    "gradle-testing-base"
    "gradle-testing-jvm"
    "gradle-testing-native"
    "gradle-tooling-api-builders"
  ];
  sourceSubprojects = [
    "announce"
    "base-services"
    "base-services-groovy"
    "build-comparison"
    "build-init"
    "cli"
    "core"
    "dependency-management"
    "diagnostics"
    "ear"
    "installation-beacon"
    "ivy"
    "jacoco"
    "javascript"
    "jetty"
    "jvm-services"
    "language-groovy"
    "language-java"
    "language-jvm"
    "language-native"
    "launcher"
    "logging"
    "maven"
    "messaging"
    "model-core"
    "model-groovy"
    "native"
    "open-api"
    "osgi"
    "platform-base"
    "platform-jvm"
    "platform-native"
    "plugin-development"
    "plugin-use"
    "plugins"
    "process-services"
    "publish"
    "reporting"
    "resources"
    "resources-http"
    "resources-s3"
    "resources-sftp"
    "signing"
    "test-kit"
    "testing-base"
    "testing-jvm"
    "testing-native"
    "tooling-api"
    "tooling-api-builders"
    "ui"
    "wrapper"
  ];
  binaryRuntimeModules = [
    "gradle-docs"
    "gradle-script-kotlin"
  ];
  binaryPluginModules = [
    "gradle-antlr"
    "gradle-code-quality"
    "gradle-ide"
    "gradle-ide-native"
    "gradle-ide-play"
    "gradle-language-scala"
    "gradle-platform-play"
    "gradle-scala"
  ];
  builtRuntimeModules = builtins.filter (m: !(builtins.elem m binaryRuntimeModules)) gradleModules;
  builtPluginModules = builtins.filter (m: !(builtins.elem m binaryPluginModules)) pluginModules;
  pluginsPropertyModules = [
    "gradle-announce"
    "gradle-antlr"
    "gradle-build-comparison"
    "gradle-build-init"
    "gradle-code-quality"
    "gradle-diagnostics"
    "gradle-ear"
    "gradle-ide"
    "gradle-ide-native"
    "gradle-ide-play"
    "gradle-ivy"
    "gradle-jacoco"
    "gradle-javascript"
    "gradle-jetty"
    "gradle-language-groovy"
    "gradle-language-java"
    "gradle-language-jvm"
    "gradle-language-native"
    "gradle-language-scala"
    "gradle-maven"
    "gradle-osgi"
    "gradle-platform-base"
    "gradle-platform-jvm"
    "gradle-platform-native"
    "gradle-platform-play"
    "gradle-plugin-development"
    "gradle-plugin-use"
    "gradle-plugins"
    "gradle-publish"
    "gradle-reporting"
    "gradle-resources-http"
    "gradle-resources-s3"
    "gradle-resources-sftp"
    "gradle-scala"
    "gradle-signing"
    "gradle-testing-base"
    "gradle-testing-jvm"
    "gradle-testing-native"
    "gradle-tooling-api-builders"
    "gradle-wrapper"
  ];

  mkGradle' =
    {
      ...
    }:
    let
      bootstrapDepsDist = fetchurl {
        url = "https://services.gradle.org/distributions/gradle-${version}-bin.zip";
        hash = "sha256-3/+ff7910CXPW097YeqeJHV/dKaTS6cklljn4t6dMp8=";
      };
    in
    stdenv.mkDerivation {
      pname = "gradle";
      inherit version;

      passthru = {
        bootstrapGradle = gradle_2_14_1;
        jdk = jdk8_headless;
      };

      src = fetchFromGitHub {
        owner = "gradle";
        repo = "gradle";
        tag = "v3.0.0-M1";
        hash = "sha256-oi06Ab7H9pepEpz0TzH2W/QQJfIHFF/fttaNXTNuLAY=";
      };

      nativeBuildInputs = [
        jdk8_headless
        unzip
      ];

      dontConfigure = true;

      buildPhase = ''
        runHook preBuild

        export JAVA_HOME=${jdk8_headless}
        export HOME="$TMPDIR/home"
        mkdir -p "$HOME" build/lib build/all/classes build/bootstrap build/upstream build/meta

        unzip -q ${bootstrapDepsDist} -d build/upstream
        mkdir -p build/bootstrap/gradle-${version}
        cp -a build/upstream/gradle-${version}/bin build/bootstrap/gradle-${version}/
        cp -a build/upstream/gradle-${version}/init.d build/bootstrap/gradle-${version}/
        cp -a build/upstream/gradle-${version}/media build/bootstrap/gradle-${version}/
        cp -a build/upstream/gradle-${version}/LICENSE build/upstream/gradle-${version}/NOTICE build/bootstrap/gradle-${version}/
        mkdir -p build/bootstrap/gradle-${version}/lib/plugins

        cp build/upstream/gradle-${version}/lib/*.jar build/bootstrap/gradle-${version}/lib/
        cp build/upstream/gradle-${version}/lib/plugins/*.jar build/bootstrap/gradle-${version}/lib/plugins/

        cp build/bootstrap/gradle-${version}/lib/*.jar build/lib/
        cp build/bootstrap/gradle-${version}/lib/plugins/*.jar build/lib/
        chmod u+w build/lib/*.jar
        for jar in build/lib/gradle-*.jar; do
          name="$(basename "$jar")"
          if echo "$name" | grep -q '^gradle-script-kotlin-'; then
            continue
          fi
          rm -f "$jar"
        done

        : > build/all-sources.txt
        for subproject in ${lib.escapeShellArgs sourceSubprojects}; do
          for dir in "subprojects/$subproject/src/main/java" "subprojects/$subproject/src/main/groovy"; do
            if [ -d "$dir" ]; then
              find "$dir" -type f \( -name '*.groovy' -o -name '*.java' \) | sort >> build/all-sources.txt
            fi
          done
        done
        sort -u build/all-sources.txt -o build/all-sources.txt

        compileClasspath="$(printf '%s:' build/lib/*.jar)''${JAVA_HOME}/lib/tools.jar"
        "''$JAVA_HOME/bin/java" -noverify -Dfile.encoding=UTF-8 -Xmx3000m -classpath "$compileClasspath" \
          org.codehaus.groovy.tools.FileSystemCompiler \
          --classpath "$compileClasspath" \
          --encoding UTF-8 \
          -j \
          -d build/all/classes \
          @build/all-sources.txt

        for subproject in ${lib.escapeShellArgs sourceSubprojects}; do
          if [ -d "subprojects/$subproject/src/main/resources" ]; then
            cp -a "subprojects/$subproject/src/main/resources"/. build/all/classes/
          fi
        done

        (
          cd build/meta
          "''$JAVA_HOME/bin/jar" xf ../upstream/gradle-${version}/lib/gradle-docs-${version}.jar default-imports.txt api-mapping.txt
          cp default-imports.txt ../all/classes/
          cp api-mapping.txt ../all/classes/
        )

        mkdir -p build/all/classes/META-INF/services
        while IFS= read -r jar; do
          jarPath="$(readlink -f "$jar")"
          if "''$JAVA_HOME/bin/jar" tf "$jarPath" | grep -q '^META-INF/services/'; then
            (
              cd build/all/classes
              "''$JAVA_HOME/bin/jar" xf "$jarPath" META-INF/services
            )
          fi
        done < <(find build/upstream/gradle-${version}/lib build/upstream/gradle-${version}/lib/plugins -type f -name 'gradle-*.jar' | sort)

        mkdir -p build/all/classes/org/gradle
        cat > build/all/classes/org/gradle/build-receipt.properties <<EOF
        buildTimestamp=20160410000000+0000
        commitId=direct-bootstrap
        isSnapshot=false
        versionBase=${version}
        versionNumber=${version}
        EOF

        printf 'plugins=%s\n' "${lib.concatStringsSep "," pluginsPropertyModules}" > build/all/classes/gradle-plugins.properties

        runtime="$(cd build/bootstrap/gradle-${version}/lib && ls *.jar | grep -v '^gradle-' | paste -sd, -)"
        pluginRuntime="$(cd build/bootstrap/gradle-${version}/lib/plugins && ls *.jar | grep -v '^gradle-' | paste -sd, -)"

        for module in ${lib.escapeShellArgs builtRuntimeModules}; do
          {
            printf 'runtime=%s\n' "$runtime"
            printf 'projects=\n'
          } > "build/all/classes/$module-classpath.properties"
        done
        for module in ${lib.escapeShellArgs builtPluginModules}; do
          {
            printf 'runtime=%s\n' "$pluginRuntime"
            printf 'projects=\n'
          } > "build/all/classes/$module-classpath.properties"
        done

        (
          cd build/all/classes
          "''$JAVA_HOME/bin/jar" cf ../gradle-bootstrap-${version}.jar .
        )

        runHook postBuild
      '';

      installPhase = ''
        runHook preInstall

        gradleHome="$out/libexec/gradle"
        mkdir -p "$gradleHome/lib/plugins" "$out/bin"

        cp build/bootstrap/gradle-${version}/lib/*.jar "$gradleHome/lib/"
        cp build/bootstrap/gradle-${version}/lib/plugins/*.jar "$gradleHome/lib/plugins/"

        for jar in "$gradleHome"/lib/gradle-*.jar; do
          name="$(basename "$jar")"
          if echo "$name" | grep -q '^gradle-script-kotlin-'; then
            continue
          fi
          rm -f "$jar"
        done
        rm -f "$gradleHome"/lib/plugins/gradle-*.jar

        for module in ${lib.escapeShellArgs builtRuntimeModules}; do
          cp build/all/gradle-bootstrap-${version}.jar "$gradleHome/lib/$module-${version}.jar"
        done
        for module in ${lib.escapeShellArgs builtPluginModules}; do
          cp build/all/gradle-bootstrap-${version}.jar "$gradleHome/lib/plugins/$module-${version}.jar"
        done

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
          -classpath "${placeholder "out"}/libexec/gradle/lib/gradle-launcher-${version}.jar" \
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
        platforms = lib.platforms.linux;
      };
    };

  unwrapped = callPackage mkGradle' { };
in
callPackage gradle-packages.wrapGradle {
  gradle-unwrapped = unwrapped;
}
