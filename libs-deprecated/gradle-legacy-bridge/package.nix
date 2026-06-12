{
  callPackage,
  buildMavenRepository,
  lib,
  stdenv,
  fetchFromGitHub,
  gradle-packages,
  jdk8_headless,
  coreutils,
  findutils,
  gnugrep,
  gnused,
  which,
  unzip,
  zip,
}:
lib.extendMkDerivation {
  constructDrv = stdenv.mkDerivation;

  excludeDrvArgNames = [
    "version"
    "tag"
    "hash"
    "bootstrapGradle"
    "bootstrapDistZip"
    "bootstrapDistLibJars"
    "bootstrapDistPluginJars"
    "bootstrapDistInstallLibJars"
    "bootstrapDistInstallPluginJars"
    "preserveBootstrapRuntimeModules"
    "preserveBootstrapPluginModules"
    "bootstrapCompileExcludeJars"
    "sourceSubprojects"
    "kotlinSourceSubprojects"
    "kotlinSourcePaths"
    "builtRuntimeModules"
    "builtPluginModules"
    "pluginClasspathModules"
    "implementationPluginModules"
    "extraLibs"
    "extraPluginLibs"
    "jdk"
    "buildTimestamp"
    "buildTimestampIso"
    "kotlinDslVersion"
    "patches"
    "patchFlags"
    "kotlinBootstrapRepo"
  ];

  extendDrvArgs =
    finalAttrs:
    {
      version,
      tag,
      hash,
      bootstrapGradle,
      bootstrapDistZip ? null,
      bootstrapDistLibJars ? [ ],
      bootstrapDistPluginJars ? [ ],
      bootstrapDistInstallLibJars ? [ ],
      bootstrapDistInstallPluginJars ? [ ],
      preserveBootstrapRuntimeModules ? [ ],
      preserveBootstrapPluginModules ? [ ],
      bootstrapCompileExcludeJars ? [ ],
      sourceSubprojects,
      kotlinSourceSubprojects ? sourceSubprojects,
      kotlinSourcePaths ? [ ],
      builtRuntimeModules,
      builtPluginModules,
      pluginClasspathModules ? [ ],
      implementationPluginModules ? [ ],
      extraLibs ? [ ],
      extraPluginLibs ? [ ],
      jdk ? jdk8_headless,
      buildTimestamp ? "19700101000000+0000",
      buildTimestampIso ? "1970-01-01 00\\:00\\:00 UTC",
      kotlinDslVersion ? null,
      patches ? [ ],
      patchFlags ? [ ],
      kotlinBootstrapRepo ? null,
      ...
    }:
    let
      pluginsPropertyModules = builtPluginModules ++ pluginClasspathModules ++ [ "gradle-wrapper" ];
      implementationPluginsPropertyModules = implementationPluginModules;
    in
    {
      pname = "gradle";
      inherit version;

      passthru = {
        inherit bootstrapGradle;
        inherit jdk;
      };

      src = fetchFromGitHub {
        owner = "gradle";
        repo = "gradle";
        inherit tag hash;
      };

      inherit patches patchFlags;

      nativeBuildInputs = [
        jdk
        unzip
        zip
      ];

      dontConfigure = true;

      buildPhase = ''
        runHook preBuild

        export JAVA_HOME=${jdk}
        export HOME="$TMPDIR/home"
        mkdir -p "$HOME" build/lib build/all/classes build/bootstrap build/meta

        cp -a --dereference ${bootstrapGradle}/libexec/gradle/. build/bootstrap/gradle-${version}/
        chmod -R u+w build/bootstrap/gradle-${version}
        mkdir -p build/bootstrap/gradle-${version}/lib/plugins
        if [ -n "${if bootstrapDistZip == null then "" else builtins.toString bootstrapDistZip}" ]; then
          bootstrapZip="${if bootstrapDistZip == null then "" else builtins.toString bootstrapDistZip}"
          for jar in ${lib.escapeShellArgs bootstrapDistLibJars}; do
            if unzip -Z1 "$bootstrapZip" "gradle-${version}/lib/$jar" >/dev/null 2>&1; then
              unzip -oq "$bootstrapZip" "gradle-${version}/lib/$jar" -d build/bootstrap
            fi
          done
          for jar in ${lib.escapeShellArgs bootstrapDistPluginJars}; do
            if unzip -Z1 "$bootstrapZip" "gradle-${version}/lib/plugins/$jar" >/dev/null 2>&1; then
              unzip -oq "$bootstrapZip" "gradle-${version}/lib/plugins/$jar" -d build/bootstrap
            fi
          done
        fi
        rm -f build/bootstrap/gradle-${version}/lib/logback-classic-*.jar
        cp ${lib.escapeShellArgs extraLibs} build/bootstrap/gradle-${version}/lib/ 2>/dev/null || true
        cp ${lib.escapeShellArgs extraPluginLibs} build/bootstrap/gradle-${version}/lib/plugins/ 2>/dev/null || true

        cp build/bootstrap/gradle-${version}/lib/*.jar build/lib/
        cp build/bootstrap/gradle-${version}/lib/plugins/*.jar build/lib/
        chmod u+w build/lib/*.jar
        for jar in ${lib.escapeShellArgs bootstrapCompileExcludeJars}; do
          rm -f build/lib/"$jar"
        done
        for module in ${lib.escapeShellArgs builtRuntimeModules}; do
          rm -f build/lib/"$module"-*.jar
        done
        for module in ${lib.escapeShellArgs builtPluginModules}; do
          rm -f build/lib/"$module"-*.jar
        done

        : > build/all-sources.txt
        : > build/all-kotlin-sources.txt
        for subproject in ${lib.escapeShellArgs sourceSubprojects}; do
          for dir in "subprojects/$subproject/src/main/java" "subprojects/$subproject/src/main/groovy"; do
            if [ -d "$dir" ]; then
              find "$dir" -type f \( -name '*.groovy' -o -name '*.java' \) | sort >> build/all-sources.txt
            fi
          done
        done
        for subproject in ${lib.escapeShellArgs kotlinSourceSubprojects}; do
          dir="subprojects/$subproject/src/main/kotlin"
          if [ -d "$dir" ]; then
            find "$dir" -type f -name '*.kt' | sort >> build/all-kotlin-sources.txt
          fi
        done
        for path in ${lib.escapeShellArgs kotlinSourcePaths}; do
          if [ -d "$path" ]; then
            find "$path" -type f -name '*.kt' | sort >> build/all-kotlin-sources.txt
          elif [ -f "$path" ]; then
            printf '%s\n' "$path" >> build/all-kotlin-sources.txt
          fi
        done
        sort -u build/all-sources.txt -o build/all-sources.txt
        sort -u build/all-kotlin-sources.txt -o build/all-kotlin-sources.txt

        tmpSources="$(mktemp)"
        declare -A seenPackageInfo=()
        while IFS= read -r source; do
          if [ "''${source##*/}" = package-info.java ]; then
            packageName="$(${gnugrep}/bin/grep -E '^package ' "$source" | head -n1 | ${gnused}/bin/sed -E 's/^package ([^;]+);/\1/')"
            if [ -n "$packageName" ] && [ -n "''${seenPackageInfo[$packageName]:-}" ]; then
              continue
            fi
            seenPackageInfo["$packageName"]=1
          fi
          printf '%s\n' "$source" >> "$tmpSources"
        done < build/all-sources.txt
        mv "$tmpSources" build/all-sources.txt

        if [ -f subprojects/core/src/main/java/org/gradle/initialization/InstantExecution.java ]; then
          mkdir -p build/generated-src/org/gradle/bootstrap
          cat > build/generated-src/org/gradle/bootstrap/NoOpInstantExecution.java <<'EOF'
        package org.gradle.bootstrap;

        import org.gradle.initialization.InstantExecution;
        import org.gradle.internal.service.ServiceRegistration;
        import org.gradle.internal.service.scopes.AbstractPluginServiceRegistry;

        public class NoOpInstantExecution implements InstantExecution {
            @Override
            public boolean canExecuteInstantaneously() {
                return false;
            }

            @Override
            public void saveTaskGraph() {
            }

            @Override
            public void loadTaskGraph() {
            }

            public static class Services extends AbstractPluginServiceRegistry {
                @Override
                public void registerGradleServices(ServiceRegistration registration) {
                    registration.add(InstantExecution.class, new NoOpInstantExecution());
                }
            }
        }
        EOF
          printf '%s\n' build/generated-src/org/gradle/bootstrap/NoOpInstantExecution.java >> build/all-sources.txt
        fi

        if [ -n "${if kotlinDslVersion == null then "" else builtins.toString kotlinDslVersion}" ]; then
          mkdir -p build/generated-kotlin/org/gradle/kotlin/dsl
          embeddedKotlinVersion="${
            if kotlinDslVersion == null then "" else builtins.toString kotlinDslVersion
          }"
          cat > build/generated-kotlin/org/gradle/kotlin/dsl/KotlinDependencyExtensions.kt <<EOF
        package org.gradle.kotlin.dsl

        import org.gradle.api.artifacts.dsl.DependencyHandler
        import org.gradle.plugin.use.PluginDependenciesSpec
        import org.gradle.plugin.use.PluginDependencySpec

        val embeddedKotlinVersion = "$embeddedKotlinVersion"

        fun DependencyHandler.embeddedKotlin(module: String): Any =
            kotlin(module, embeddedKotlinVersion)

        fun DependencyHandler.kotlin(module: String, version: String? = null): Any =
            "org.jetbrains.kotlin:kotlin-''${module}''${version?.let { \":\$it\" } ?: \"\"}"

        fun PluginDependenciesSpec.kotlin(module: String): PluginDependencySpec =
            id("org.jetbrains.kotlin.''${module}")
        EOF
          printf '%s\n' build/generated-kotlin/org/gradle/kotlin/dsl/KotlinDependencyExtensions.kt >> build/all-kotlin-sources.txt
        fi

        compileClasspath="$(printf '%s:' build/lib/*.jar)''${JAVA_HOME}/lib/tools.jar"
        "''$JAVA_HOME/bin/java" -noverify -Dfile.encoding=UTF-8 -Xmx3000m -classpath "$compileClasspath" \
          org.codehaus.groovy.tools.FileSystemCompiler \
          --classpath "$compileClasspath" \
          --encoding UTF-8 \
          -j \
          -d build/all/classes \
          @build/all-sources.txt

        if [ -n "${if kotlinBootstrapRepo == null then "" else builtins.toString kotlinBootstrapRepo}" ] \
          && [ -s build/all-kotlin-sources.txt ]; then
          cp ${
            if kotlinBootstrapRepo == null then "/dev/null" else "${kotlinBootstrapRepo}"
          }/*.jar build/lib/
          chmod u+w build/lib/*.jar
          kotlinCompileClasspath="build/all/classes:$(printf '%s:' build/lib/*.jar)''${JAVA_HOME}/lib/tools.jar"
          "''$JAVA_HOME/bin/java" -Dfile.encoding=UTF-8 -Xms256m -Xmx2048m -cp "$kotlinCompileClasspath" \
            org.jetbrains.kotlin.cli.jvm.K2JVMCompiler \
            -no-stdlib \
            -no-reflect \
            -jvm-target 1.8 \
            -classpath "$kotlinCompileClasspath" \
            -d build/all/classes \
            @build/all-kotlin-sources.txt
        fi

        for subproject in ${lib.escapeShellArgs sourceSubprojects}; do
          if [ -d "subprojects/$subproject/src/main/resources" ]; then
            cp -a "subprojects/$subproject/src/main/resources"/. build/all/classes/
          fi
        done

        serviceFile="META-INF/services/org.gradle.internal.service.scopes.PluginServiceRegistry"
        mkdir -p "build/all/classes/$(dirname "$serviceFile")"
        : > "build/all/classes/$serviceFile"
        for subproject in ${lib.escapeShellArgs sourceSubprojects}; do
          srcService="subprojects/$subproject/src/main/resources/$serviceFile"
          if [ -f "$srcService" ]; then
            cat "$srcService" >> "build/all/classes/$serviceFile"
            printf '\n' >> "build/all/classes/$serviceFile"
          fi
        done
        grep -v '^\s*#' "build/all/classes/$serviceFile" | grep -v '^\s*$' | sort -u > build/plugin-service-registry.txt
        mv build/plugin-service-registry.txt "build/all/classes/$serviceFile"

        if [ -f build/all/classes/org/gradle/bootstrap/NoOpInstantExecution.class ]; then
          printf '%s\n' org.gradle.bootstrap.NoOpInstantExecution\$Services >> "build/all/classes/$serviceFile"
          sort -u "build/all/classes/$serviceFile" -o "build/all/classes/$serviceFile"
        fi

        docsJar="$(find build/bootstrap/gradle-${version}/lib -maxdepth 1 -name 'gradle-docs-*.jar' | head -n1)"
        if [ -n "$docsJar" ]; then
          for resource in default-imports.txt api-mapping.txt; do
            if unzip -p "$docsJar" "$resource" > "build/all/classes/$resource"; then
              :
            else
              rm -f "build/all/classes/$resource"
            fi
          done
        fi

        mkdir -p build/all/classes/org/gradle
        cat > build/all/classes/org/gradle/build-receipt.properties <<EOF
        baseVersion=${version}
        buildTimestamp=${buildTimestamp}
        buildTimestampIso=${buildTimestampIso}
        commitId=direct-bootstrap
        isSnapshot=false
        versionBase=${version}
        versionNumber=${version}
        EOF

        printf 'plugins=%s\n' "${lib.concatStringsSep "," pluginsPropertyModules}" > build/all/classes/gradle-plugins.properties
        printf 'plugins=%s\n' "${lib.concatStringsSep "," implementationPluginsPropertyModules}" > build/all/classes/gradle-implementation-plugins.properties

        if [ -n "${if kotlinDslVersion == null then "" else kotlinDslVersion}" ]; then
          printf 'kotlin=%s\n' "${
            if kotlinDslVersion == null then "" else kotlinDslVersion
          }" > build/all/classes/gradle-kotlin-dsl-versions.properties
        fi

        if [ -n "${if bootstrapDistZip == null then "" else builtins.toString bootstrapDistZip}" ]; then
          bootstrapZip="${if bootstrapDistZip == null then "" else builtins.toString bootstrapDistZip}"
          preserveModuleProperties() {
            local jarPath="$1"
            local propertyName="$3"
            if unzip -Z1 "$bootstrapZip" "$jarPath" >/dev/null 2>&1; then
              local preserveTmp
              preserveTmp="$(mktemp -d)"
              unzip -oq "$bootstrapZip" "$jarPath" -d "$preserveTmp"
              unzip -p "$preserveTmp/$jarPath" "$propertyName" > "build/all/classes/$propertyName"
              rm -rf "$preserveTmp"
            fi
          }

          for module in ${lib.escapeShellArgs preserveBootstrapRuntimeModules}; do
            preserveModuleProperties "gradle-${version}/lib/$module-${version}.jar" "$module" "$module-classpath.properties"
          done
          for module in ${lib.escapeShellArgs preserveBootstrapPluginModules}; do
            preserveModuleProperties "gradle-${version}/lib/plugins/$module-${version}.jar" "$module" "$module-classpath.properties"
          done
          preserveModuleProperties \
            "gradle-${version}/lib/gradle-kotlin-dsl-${version}.jar" \
            "gradle-kotlin-dsl" \
            "gradle-kotlin-dsl-versions.properties"
        fi

        runtime="$(cd build/bootstrap/gradle-${version}/lib && ls *.jar | grep -v '^gradle-' | paste -sd, -)"
        pluginRuntime="$(cd build/bootstrap/gradle-${version}/lib/plugins && ls *.jar | grep -v '^gradle-' | paste -sd, -)"
        if [ -n "${
          if kotlinBootstrapRepo == null then "" else builtins.toString kotlinBootstrapRepo
        }" ]; then
          kotlinRuntime="$(cd ${
            if kotlinBootstrapRepo == null then "/dev/null" else "${kotlinBootstrapRepo}"
          } && ls *.jar | paste -sd, -)"
          if [ -n "$kotlinRuntime" ]; then
            runtime="$runtime,$kotlinRuntime"
            pluginRuntime="$pluginRuntime,$kotlinRuntime"
          fi
        fi

        for module in ${lib.escapeShellArgs builtRuntimeModules}; do
          if [ ! -f "build/all/classes/$module-classpath.properties" ]; then
            {
              printf 'runtime=%s\n' "$runtime"
              printf 'projects=\n'
            } > "build/all/classes/$module-classpath.properties"
          fi
        done
        for module in ${lib.escapeShellArgs builtPluginModules}; do
          if [ ! -f "build/all/classes/$module-classpath.properties" ]; then
            {
              printf 'runtime=%s\n' "$pluginRuntime"
              printf 'projects=\n'
            } > "build/all/classes/$module-classpath.properties"
          fi
        done

        if printf '%s\n' ${lib.escapeShellArgs builtRuntimeModules} | grep -qx 'gradle-runtime-api-info'; then
          mkdir -p build/all/classes/org/gradle/api/internal/runtimeshaded
          : > build/all/classes/org/gradle/api/internal/runtimeshaded/api-relocated.txt
          : > build/all/classes/org/gradle/api/internal/runtimeshaded/test-kit-relocated.txt
        fi

        serviceRegistryFile="build/all/classes/META-INF/services/org.gradle.internal.service.scopes.PluginServiceRegistry"
        if [ -f "$serviceRegistryFile" ]; then
          tmpServiceRegistry="$(mktemp)"
          grep -vx 'org.gradle.instantexecution.InstantExecutionServices' \
            "$serviceRegistryFile" > "$tmpServiceRegistry" || true
          mv "$tmpServiceRegistry" "$serviceRegistryFile"
        fi

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

        if [ -n "${
          if kotlinBootstrapRepo == null then "" else builtins.toString kotlinBootstrapRepo
        }" ]; then
          cp ${
            if kotlinBootstrapRepo == null then "/dev/null" else "${kotlinBootstrapRepo}"
          }/*.jar "$gradleHome/lib/"
        fi

        if [ -n "${if bootstrapDistZip == null then "" else builtins.toString bootstrapDistZip}" ]; then
          find "$gradleHome/lib" -maxdepth 1 -type f -name 'gradle-*.jar' ! -name "*-${version}.jar" -delete
          find "$gradleHome/lib/plugins" -maxdepth 1 -type f -name 'gradle-*.jar' ! -name "*-${version}.jar" -delete
        fi

        if [ -n "${if bootstrapDistZip == null then "" else builtins.toString bootstrapDistZip}" ]; then
          bootstrapZip="${if bootstrapDistZip == null then "" else builtins.toString bootstrapDistZip}"
          installOverlay="$(mktemp -d)"
          for jar in ${lib.escapeShellArgs bootstrapDistInstallLibJars}; do
            if unzip -Z1 "$bootstrapZip" "gradle-${version}/lib/$jar" >/dev/null 2>&1; then
              unzip -oq "$bootstrapZip" "gradle-${version}/lib/$jar" -d "$installOverlay"
              cp "$installOverlay/gradle-${version}/lib/$jar" "$gradleHome/lib/"
            fi
          done
          for jar in ${lib.escapeShellArgs bootstrapDistInstallPluginJars}; do
            if unzip -Z1 "$bootstrapZip" "gradle-${version}/lib/plugins/$jar" >/dev/null 2>&1; then
              unzip -oq "$bootstrapZip" "gradle-${version}/lib/plugins/$jar" -d "$installOverlay"
              cp "$installOverlay/gradle-${version}/lib/plugins/$jar" "$gradleHome/lib/plugins/"
            fi
          done
          rm -rf "$installOverlay"
        fi

        for module in ${lib.escapeShellArgs builtRuntimeModules}; do
          rm -f "$gradleHome/lib/$module"-*.jar
        done
        for module in ${lib.escapeShellArgs builtPluginModules}; do
          rm -f "$gradleHome/lib/plugins/$module"-*.jar
        done

        for module in ${lib.escapeShellArgs builtRuntimeModules}; do
          cp build/all/gradle-bootstrap-${version}.jar "$gradleHome/lib/$module-${version}.jar"
        done
        for module in ${lib.escapeShellArgs builtPluginModules}; do
          cp build/all/gradle-bootstrap-${version}.jar "$gradleHome/lib/plugins/$module-${version}.jar"
        done

        cat > "$out/bin/gradle" <<'EOF'
        #!${stdenv.shell}
        export JAVA_HOME="''${JAVA_HOME:-${jdk}}"
        export PATH="${
          lib.makeBinPath [
            coreutils
            findutils
            gnugrep
            gnused
            which
            jdk
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
        platforms = lib.platforms.unix;
      };
    };
}
