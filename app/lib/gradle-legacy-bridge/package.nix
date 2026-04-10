{
  callPackage,
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
}:
{
  version,
  tag,
  hash,
  bootstrapGradle,
  sourceSubprojects,
  builtRuntimeModules,
  builtPluginModules,
  implementationPluginModules ? [ ],
  extraLibs ? [ ],
  extraPluginLibs ? [ ],
  buildTimestamp ? "19700101000000+0000",
  patches ? [ ],
  patchFlags ? [ ],
}:
let
  pluginsPropertyModules = builtPluginModules ++ [ "gradle-wrapper" ];
  implementationPluginsPropertyModules = implementationPluginModules;

  mkGradle' =
    {
      ...
    }:
    stdenv.mkDerivation {
      pname = "gradle";
      inherit version;

      passthru = {
        inherit bootstrapGradle;
        jdk = jdk8_headless;
      };

      src = fetchFromGitHub {
        owner = "gradle";
        repo = "gradle";
        inherit tag hash;
      };

      inherit patches patchFlags;

      nativeBuildInputs = [
        jdk8_headless
        unzip
      ];

      dontConfigure = true;

      buildPhase = ''
        runHook preBuild

        export JAVA_HOME=${jdk8_headless}
        export HOME="$TMPDIR/home"
        mkdir -p "$HOME" build/lib build/all/classes build/bootstrap build/meta

        cp -a --dereference ${bootstrapGradle}/libexec/gradle/. build/bootstrap/gradle-${version}/
        chmod -R u+w build/bootstrap/gradle-${version}
        mkdir -p build/bootstrap/gradle-${version}/lib/plugins
        cp ${lib.escapeShellArgs extraLibs} build/bootstrap/gradle-${version}/lib/ 2>/dev/null || true
        cp ${lib.escapeShellArgs extraPluginLibs} build/bootstrap/gradle-${version}/lib/plugins/ 2>/dev/null || true

        cp build/bootstrap/gradle-${version}/lib/*.jar build/lib/
        cp build/bootstrap/gradle-${version}/lib/plugins/*.jar build/lib/
        chmod u+w build/lib/*.jar
        for module in ${lib.escapeShellArgs builtRuntimeModules}; do
          rm -f build/lib/"$module"-*.jar
        done
        for module in ${lib.escapeShellArgs builtPluginModules}; do
          rm -f build/lib/"$module"-*.jar
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

        mkdir -p build/all/classes/org/gradle
        cat > build/all/classes/org/gradle/build-receipt.properties <<EOF
        buildTimestamp=${buildTimestamp}
        commitId=direct-bootstrap
        isSnapshot=false
        versionBase=${version}
        versionNumber=${version}
        EOF

        printf 'plugins=%s\n' "${lib.concatStringsSep "," pluginsPropertyModules}" > build/all/classes/gradle-plugins.properties
        printf 'plugins=%s\n' "${lib.concatStringsSep "," implementationPluginsPropertyModules}" > build/all/classes/gradle-implementation-plugins.properties

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

        if printf '%s\n' ${lib.escapeShellArgs builtRuntimeModules} | grep -qx 'gradle-runtime-api-info'; then
          mkdir -p build/all/classes/org/gradle/api/internal/runtimeshaded
          : > build/all/classes/org/gradle/api/internal/runtimeshaded/api-relocated.txt
          : > build/all/classes/org/gradle/api/internal/runtimeshaded/test-kit-relocated.txt
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
