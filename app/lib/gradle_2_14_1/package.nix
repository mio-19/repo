{
  callPackage,
  lib,
  stdenv,
  fetchFromGitHub,
  fetchurl,
  gradle-packages,
  gradle_2_0,
  jdk8_headless,
  coreutils,
  findutils,
  gnugrep,
  gnused,
  which,
  unzip,
}:
let
  version = "2.14.1";
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
    "gradle-build-comparison"
    "gradle-build-init"
    "gradle-dependency-management"
    "gradle-diagnostics"
    "gradle-ear"
    "gradle-ivy"
    "gradle-jacoco"
    "gradle-javascript"
    "gradle-jetty"
    "gradle-language-groovy"
    "gradle-language-java"
    "gradle-language-jvm"
    "gradle-language-native"
    "gradle-maven"
    "gradle-osgi"
    "gradle-platform-base"
    "gradle-platform-jvm"
    "gradle-platform-native"
    "gradle-plugin-development"
    "gradle-plugin-use"
    "gradle-plugins"
    "gradle-publish"
    "gradle-reporting"
    "gradle-resources-http"
    "gradle-resources-s3"
    "gradle-resources-sftp"
    "gradle-testing-base"
    "gradle-testing-jvm"
    "gradle-testing-native"
    "gradle-tooling-api-builders"
  ];
  gradlePluginsPropertyModules = pluginModules ++ [
    "gradle-wrapper"
  ];
  runtimeSubprojects = [
    "base-services"
    "base-services-groovy"
    "cli"
    "core"
    "installation-beacon"
    "jvm-services"
    "launcher"
    "logging"
    "messaging"
    "model-core"
    "model-groovy"
    "native"
    "open-api"
    "process-services"
    "resources"
    "tooling-api"
    "ui"
    "wrapper"
  ];
  pluginSubprojects = [
    "announce"
    "build-comparison"
    "build-init"
    "dependency-management"
    "diagnostics"
    "ear"
    "ivy"
    "jacoco"
    "javascript"
    "jetty"
    "language-groovy"
    "language-java"
    "language-jvm"
    "language-native"
    "maven"
    "osgi"
    "platform-base"
    "platform-jvm"
    "platform-native"
    "plugin-development"
    "plugin-use"
    "plugins"
    "publish"
    "reporting"
    "resources-http"
    "resources-s3"
    "resources-sftp"
    "testing-base"
    "testing-jvm"
    "testing-native"
    "tooling-api-builders"
  ];
  bootstrapDepsDist = fetchurl {
    url = "https://services.gradle.org/distributions/gradle-${version}-bin.zip";
    hash = "sha256-z8Ye2nHy0SpXKCJkTOE9KRlAdZXCrsPjVm0qq2+X7zk=";
  };

  mkGradle' =
    {
      ...
    }:
    stdenv.mkDerivation {
      pname = "gradle";
      inherit version;

      passthru = {
        bootstrapGradle = gradle_2_0;
        inherit bootstrapDepsDist;
        jdk = jdk8_headless;
      };

      src = fetchFromGitHub {
        owner = "gradle";
        repo = "gradle";
        tag = "v2.14.1";
        hash = "sha256-oyqnZ0dpejToxwLagrebTJVQv4X0tJPXK+lsybks9DQ=";
      };

      nativeBuildInputs = [
        jdk8_headless
        unzip
      ];

      patches = [ ./gradle-2.14.1-direct-bootstrap.patch ];

      dontConfigure = true;

      buildPhase = ''
          runHook preBuild

          export JAVA_HOME=${jdk8_headless}
          export HOME="$TMPDIR/home"
          mkdir -p "$HOME" build/lib build/runtime/classes build/plugins/classes build/bootstrap build/meta

          mkdir -p build/upstream
          cp -a ${gradle_2_0}/libexec/gradle/. build/bootstrap/gradle-${version}/
          chmod -R u+w build/bootstrap/gradle-${version}
          unzip -q ${bootstrapDepsDist} -d build/upstream

          for jar in build/bootstrap/gradle-${version}/lib/*.jar; do
            name="$(basename "$jar")"
            if ! echo "$name" | grep -q '^gradle-'; then
              rm -f "$jar"
            fi
          done
          for jar in build/bootstrap/gradle-${version}/lib/plugins/*.jar; do
            name="$(basename "$jar")"
            if ! echo "$name" | grep -q '^gradle-'; then
              rm -f "$jar"
            fi
          done
          for jar in build/upstream/gradle-${version}/lib/*.jar; do
            name="$(basename "$jar")"
            if ! echo "$name" | grep -q '^gradle-'; then
              cp "$jar" build/bootstrap/gradle-${version}/lib/
            fi
          done
          for jar in build/upstream/gradle-${version}/lib/plugins/*.jar; do
            name="$(basename "$jar")"
            if ! echo "$name" | grep -q '^gradle-'; then
              cp "$jar" build/bootstrap/gradle-${version}/lib/plugins/
            fi
          done

          cp build/bootstrap/gradle-${version}/lib/*.jar build/lib/
          cp build/bootstrap/gradle-${version}/lib/plugins/*.jar build/lib/
          chmod u+w build/lib/*.jar
          rm -f build/lib/gradle-*.jar

        : > build/runtime-sources.txt
        for subproject in ${lib.escapeShellArgs runtimeSubprojects}; do
          for dir in "subprojects/$subproject/src/main/java" "subprojects/$subproject/src/main/groovy"; do
            if [ -d "$dir" ]; then
              find "$dir" -type f \( -name '*.groovy' -o -name '*.java' \) | sort >> build/runtime-sources.txt
            fi
          done
        done
        sort -u build/runtime-sources.txt -o build/runtime-sources.txt

        compileClasspath="$(printf '%s:' build/lib/*.jar)''${JAVA_HOME}/lib/tools.jar"
        "''$JAVA_HOME/bin/java" -noverify -Dfile.encoding=UTF-8 -Xmx2500m -classpath "$compileClasspath" \
          org.codehaus.groovy.tools.FileSystemCompiler \
          --classpath "$compileClasspath" \
          --encoding UTF-8 \
          -j \
          -d build/runtime/classes \
          @build/runtime-sources.txt

        pluginsClasspath="build/runtime/classes:$compileClasspath"
        : > build/plugins-sources.txt
        for subproject in ${lib.escapeShellArgs pluginSubprojects}; do
          for dir in "subprojects/$subproject/src/main/java" "subprojects/$subproject/src/main/groovy"; do
            if [ -d "$dir" ]; then
              find "$dir" -type f \( -name '*.groovy' -o -name '*.java' \) | sort >> build/plugins-sources.txt
            fi
          done
        done
        sort -u build/plugins-sources.txt -o build/plugins-sources.txt
        "''$JAVA_HOME/bin/java" -noverify -Dfile.encoding=UTF-8 -Xmx2500m -classpath "$pluginsClasspath" \
          org.codehaus.groovy.tools.FileSystemCompiler \
          --classpath "$pluginsClasspath" \
          --encoding UTF-8 \
          -j \
          -d build/plugins/classes \
          @build/plugins-sources.txt

        for subproject in ${lib.escapeShellArgs runtimeSubprojects}; do
          if [ -d "subprojects/$subproject/src/main/resources" ]; then
            cp -a "subprojects/$subproject/src/main/resources/." build/runtime/classes/
          fi
        done
        for subproject in ${lib.escapeShellArgs pluginSubprojects}; do
          if [ -d "subprojects/$subproject/src/main/resources" ]; then
            cp -a "subprojects/$subproject/src/main/resources/." build/plugins/classes/
          fi
        done

        (
          cd build/meta
          "''$JAVA_HOME/bin/jar" xf ../upstream/gradle-${version}/lib/gradle-docs-${version}.jar default-imports.txt api-mapping.txt
          cp default-imports.txt ../runtime/classes/
          cp api-mapping.txt ../runtime/classes/
        )

        mkdir -p build/runtime/classes/META-INF/services build/plugins/classes/META-INF/services
        cat > build/runtime/classes/META-INF/services/org.gradle.internal.service.scopes.PluginServiceRegistry <<'EOF'
        org.gradle.tooling.internal.provider.LauncherServices
        EOF
        cat > build/plugins/classes/META-INF/services/org.gradle.internal.service.scopes.PluginServiceRegistry <<'EOF'
        org.gradle.buildinit.plugins.internal.BuildInitServices
        org.gradle.api.internal.artifacts.DependencyServices
        org.gradle.api.reporting.components.internal.DiagnosticsServices
        org.gradle.api.publish.ivy.internal.IvyPublishServices
        org.gradle.language.java.internal.JavaToolChainServiceRegistry
        org.gradle.language.java.internal.JavaLanguagePluginServiceRegistry
        org.gradle.language.jvm.internal.JvmPluginServiceRegistry
        org.gradle.language.nativeplatform.internal.registry.NativeLanguageServices
        org.gradle.api.publish.maven.internal.MavenPublishServices
        org.gradle.platform.base.internal.registry.ComponentModelBaseServiceRegistry
        org.gradle.jvm.internal.services.PlatformJvmServices
        org.gradle.nativeplatform.internal.services.NativeBinaryServices
        org.gradle.plugin.use.internal.PluginUsePluginServiceRegistry
        org.gradle.api.internal.tasks.CompileServices
        org.gradle.api.publish.internal.PublishServices
        org.gradle.internal.resource.transport.http.HttpResourcesPluginServiceRegistry
        org.gradle.internal.resource.transport.aws.s3.S3ResourcesPluginServiceRegistry
        org.gradle.internal.resource.transport.sftp.SftpResourcesPluginServiceRegistry
        org.gradle.jvm.test.internal.services.JvmTestingServices
        org.gradle.nativeplatform.test.internal.services.NativeTestingServices
        org.gradle.tooling.internal.provider.runner.ToolingBuilderServices
        EOF
        cat > build/plugins/classes/META-INF/services/org.gradle.api.internal.artifacts.DependencyManagementServices <<'EOF'
        org.gradle.api.internal.artifacts.DefaultDependencyManagementServices
        EOF

        mkdir -p build/runtime/classes/org/gradle
        cat > build/runtime/classes/org/gradle/build-receipt.properties <<EOF
        buildTimestamp=20160718063837+0000
        commitId=direct-bootstrap
        isSnapshot=false
        versionBase=${version}
        versionNumber=${version}
        EOF

        printf 'plugins=%s\n' "${lib.concatStringsSep "," gradlePluginsPropertyModules}" > build/runtime/classes/gradle-plugins.properties

        runtime="$(cd build/bootstrap/gradle-${version}/lib && ls *.jar | grep -v '^gradle-' | paste -sd, -)"
        pluginRuntime="$(cd build/bootstrap/gradle-${version}/lib/plugins && ls *.jar | grep -v '^gradle-' | paste -sd, -)"

        for module in ${lib.escapeShellArgs gradleModules}; do
          {
            printf 'runtime=%s\n' "$runtime"
            printf 'projects=\n'
          } > "build/runtime/classes/$module-classpath.properties"
        done
        for module in ${lib.escapeShellArgs pluginModules}; do
          {
            printf 'runtime=%s\n' "$pluginRuntime"
            printf 'projects=\n'
          } > "build/plugins/classes/$module-classpath.properties"
        done

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

        cp build/bootstrap/gradle-${version}/lib/*.jar "$gradleHome/lib/"
        cp build/bootstrap/gradle-${version}/lib/plugins/*.jar "$gradleHome/lib/plugins/"
        rm -f "$gradleHome"/lib/gradle-*.jar
        rm -f "$gradleHome"/lib/plugins/gradle-*.jar
        for module in ${lib.escapeShellArgs gradleModules}; do
          cp build/runtime/gradle-runtime-${version}.jar "$gradleHome/lib/$module-${version}.jar"
        done
        for module in ${lib.escapeShellArgs pluginModules}; do
          cp build/plugins/gradle-plugins-${version}.jar "$gradleHome/lib/plugins/$module-${version}.jar"
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
        platforms = lib.platforms.linux;
      };
    };

  unwrapped = callPackage mkGradle' { };
in
callPackage gradle-packages.wrapGradle {
  gradle-unwrapped = unwrapped;
}
