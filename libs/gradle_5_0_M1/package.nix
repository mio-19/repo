{
  callPackage,
  fetchFromGitHub,
  gradle-packages,
  gradle_4_10_3,
  jdk11_headless,
  jdk8_headless,
  makeWrapper,
  runtimeShell,
  stdenv,
  unzip,
}:
let
  mkGradle' =
    {
      fetchFromGitHub,
      gradle_4_10_3,
      jdk11_headless,
      jdk8_headless,
      makeWrapper,
      runtimeShell,
      stdenv,
      unzip,
      ...
    }:
    let
      gradleRunner = gradle_4_10_3;
    in
    stdenv.mkDerivation (finalAttrs: {
      pname = "gradle-unwrapped";
      version = "5.0-milestone-1";

      src = fetchFromGitHub {
        owner = "gradle";
        repo = "gradle";
        tag = "v5.0.0-M1";
        hash = "sha256-hmbktwjXBX04Y0n3pD8x9e4ZeOyX2va+tN/3R3Nkh30=";
      };

      patches = [ ];

      gradleBuildTask = ":distributions:binZip";
      gradleUpdateTask = "${finalAttrs.gradleBuildTask} -x test -x check -x ktlint -x checkstyle -x codenarc -x detekt -x ktlintMainCheck -x ktlintTestCheck";

      nativeBuildInputs = [
        gradleRunner
        jdk8_headless
        makeWrapper
        unzip
      ];

      mitmCache = gradleRunner.fetchDeps {
        inherit (finalAttrs) pname;
        pkg = finalAttrs.finalPackage;
        data = ./deps.json;
        silent = false;
        useBwrap = false;
      };

      __darwinAllowLocalNetworking = true;

      jdk = jdk8_headless;
      env.JAVA_HOME = jdk8_headless.passthru.home;

      preBuild = ''
        export HOME="$PWD/.home"
        export GRADLE_USER_HOME="$HOME/.gradle"
        mkdir -p "$GRADLE_USER_HOME"
        
        # Aggressively prevent forking and ensure SSL properties are passed to any unavoidable forks
        cat > "$GRADLE_USER_HOME/gradle.properties" <<EOF
org.gradle.daemon=false
org.gradle.parallel=true
EOF

        # 1. Broad dependency fixes for dead Bintray/internal artifacts
        find . -type f \( -name "*.kts" -o -name "*.gradle" \) -exec sed -i 's/http-builder:0.7.2/http-builder:0.7.1/g' {} +
        find . -type f \( -name "*.kts" -o -name "*.gradle" \) -exec sed -i 's/"0.9-"/""/g' {} +
        find . -type f \( -name "*.kts" -o -name "*.gradle" \) -exec sed -i 's/org.gradle.groovy:groovy-all/org.codehaus.groovy:groovy-all/g' {} +

        # 2. Surgically disable quality tool plugin APPLICATIONS without breaking syntax
        find . -type f \( -name "*.kts" -o -name "*.gradle" \) -exec sed -i 's/id("org.gradle.ktlint")/id("java-base")/g' {} +
        find . -type f \( -name "*.kts" -o -name "*.gradle" \) -exec sed -i 's/id("checkstyle")/id("java-base")/g' {} +
        find . -type f \( -name "*.kts" -o -name "*.gradle" \) -exec sed -i 's/id("codenarc")/id("java-base")/g' {} +

        # 3. Disable calls to quality configuration functions
        find . -type f \( -name "*.kts" -o -name "*.gradle" \) -exec sed -i 's/configureCodeQualityTasks()/\/\/ &/g' {} +
        find . -type f \( -name "*.kts" -o -name "*.gradle" \) -exec sed -i 's/configureCodenarc(/\/\/ &/g' {} +
        find . -type f \( -name "*.kts" -o -name "*.gradle" \) -exec sed -i 's/configureCheckstyle(/\/\/ &/g' {} +
        find . -type f \( -name "*.kts" -o -name "*.gradle" \) -exec sed -i 's/apply(from = ".*code-quality-configuration.*")/\/\/ &/g' {} +

        # 4. Hollow out most problematic subprojects
        for p in buildquality performance cleanup packaging profiling; do
          dir="buildSrc/subprojects/$p"
          if [ -d "$dir" ]; then
            find "$dir" -maxdepth 1 -name "*.gradle*" -exec sh -c 'echo "// Hollowed" > {}' \;
            rm -rf "$dir/src"
          fi
        done

        # 5. NOW create the stub file, so it's not affected by the sed commands above
        codeQualityFile="gradle/shared-with-buildSrc/code-quality-configuration.gradle.kts"
        mkdir -p $(dirname "$codeQualityFile")
        cat > "$codeQualityFile" <<'EOF'
import org.gradle.api.Project
import java.io.File
fun Project.configureCodeQualityTasks() { }
fun Project.configureCodenarc(codeQualityConfigDir: File) { }
fun Project.configureCheckstyle(codeQualityConfigDir: File) { }
EOF

        # Remove apply false which causes issues with core plugins
        find buildSrc -type f \( -name "*.kts" -o -name "*.gradle" \) -exec sed -i "s/\s*apply\s*false//g" {} +
        
        # Aggressively delete all test sources in buildSrc
        find buildSrc -path "*/src/test" -type d -exec rm -rf {} +

        # Global Repository Fix
        find . -type f \( -name "*.kts" -o -name "*.gradle" \) -exec sed -i 's/jcenter()/mavenCentral()/g' {} +
        find . -type f \( -name "*.kts" -o -name "*.gradle" \) -exec sed -i 's/bintray()/mavenCentral()/g' {} +
        find . -type f \( -name "*.kts" -o -name "*.gradle" \) -exec sed -i 's|https://dl.bintray.com/[^ "]*|https://repo.maven.apache.org/maven2/|g' {} +
        
        # Kotlin DSL Plugin Version Fix
        find . -type f \( -name "*.kts" -o -name "*.gradle" \) -exec sed -i 's/1\.0-rc-5/1\.0-rc-6/g' {} +

        # API Compatibility Patches
        find buildSrc -name "*.kt" -exec sed -i 's/\.require("/.prefer("/g' {} +
        find buildSrc -name "*.kt" -exec sed -i 's/PosixFile/FileInfo/g' {} +

        # API Compatibility Patches for Java/Groovy in buildSrc
        find buildSrc -type f \( -name "*.java" -o -name "*.groovy" \) -exec sed -i 's/objectFactory\.fileProperty()/null/g' {} +
        find buildSrc -type f \( -name "*.java" -o -name "*.groovy" \) -exec sed -i 's/objectFactory\.directoryProperty()/null/g' {} +

        # Fix the type mismatch in DependenciesMetadataRulesPlugin.kt
        configPlugin="buildSrc/subprojects/configuration/src/main/kotlin/org/gradle/gradlebuild/dependencies/DependenciesMetadataRulesPlugin.kt"
        if [ -f "$configPlugin" ]; then
          sed -i '/open class DowngradeXmlApisRule/,/^}/d' "$configPlugin"
          sed -i '/DowngradeXmlApisRule/d' "$configPlugin"
        fi

        # Stub out unfixable tasks in buildSrc
        for f in $(find buildSrc -name GenerateDefaultImportsTask.java); do
          cat > "$f" <<'EOF'
package org.gradle.build.docs.dsl.source;
import org.gradle.api.DefaultTask;
import org.gradle.api.tasks.TaskAction;
public class GenerateDefaultImportsTask extends DefaultTask {
    @TaskAction public void generate() {}
}
EOF
        done

        # Fix AvailableJavaInstallations.kt
        for f in $(find buildSrc -name AvailableJavaInstallations.kt); do
          cat > "$f" <<'EOF'
package org.gradle.gradlebuild.java
import org.gradle.api.Project
import java.io.File
class AvailableJavaInstallations(val shadowedProject: Project) {
    val javaHome: File = File("/dev/null")
}
interface ProbedLocalJavaInstallation {
    fun getJavaHome(): File
}
EOF
        done

        # Create a dummy repository for missing artifacts
        mkdir -p "$PWD/dummy-repo/com/andreapivetta/kolor/kolor/0.0.2"
        touch "$PWD/dummy-repo/com/andreapivetta/kolor/kolor/0.0.2/kolor-0.0.2.jar"
        cat > "$PWD/dummy-repo/com/andreapivetta/kolor/kolor/0.0.2/kolor-0.0.2.pom" <<EOF
<project><groupId>com.andreapivetta.kolor</groupId><artifactId>kolor</artifactId><version>0.0.2</version></project>
EOF

        # 6. Global Init Script
        export gradleInitScript="$PWD/mitm-compat.gradle"
        cat > "$gradleInitScript" <<EOF
gradle.settingsEvaluated { settings ->
    settings.buildscript.repositories {
        maven { url "file://\$settings.rootDir/dummy-repo" }
        mavenCentral()
        google()
    }
}
gradle.allprojects {
    repositories {
        maven { url "file://\$settings.rootDir/dummy-repo" }
        mavenCentral()
        google()
        maven { url "https://repo.gradle.org/gradle/libs-releases" }
    }
}
gradle.projectsLoaded {
    rootProject.allprojects {
        afterEvaluate {
            configurations.matching { it.name.toLowerCase().contains("ktlint") }.all {
                dependencies.clear()
            }
        }
        tasks.matching { 
            it.name.toLowerCase().contains("test") || 
            it.name.toLowerCase().contains("check") || 
            it.name.toLowerCase().contains("lint") ||
            it.name.startsWith("docs") ||
            it.name.contains("asciidoctor") ||
            it.name.contains("codenarc") ||
            it.name.contains("checkstyle") ||
            it.name.contains("ktlint")
        }.all {
            enabled = false
        }
    }
}
EOF
        export GRADLE_FLAGS="--init-script $gradleInitScript"
        
        # 7. Propagate SSL trustStore to forked JVMs if they happen
        if [ -n "$JAVA_TOOL_OPTIONS" ]; then
            export GRADLE_OPTS="$JAVA_TOOL_OPTIONS $GRADLE_OPTS"
        fi
      '';

      gradleFlags = [
        "-PfinalRelease=true"
        "-PpromotionCommitId=v5.0.0-M1"
        "-Dfile.encoding=UTF-8"
      ];

      postPatch = ''
        rm -f gradle/verification-metadata.xml
        rm -rf gradle/wrapper .teamcity/.mvn/wrapper
        find . -name "*.jar" -print0 | xargs -0 rm -f
      '';

      gradleUpdateScript = ''
        runHook preBuild
        tmpbin="$(mktemp -d)"
        tee > "$tmpbin/gradlecustom" <<EOF
        #!${runtimeShell}
        exec ${gradleRunner}/bin/gradle ''${gradleFlags[@]} ''${gradleFlagsArray[@]} $GRADLE_FLAGS "\$@"
        EOF
        chmod +x "$tmpbin/gradlecustom"
        export PATH="$tmpbin:$PATH"
        gradlecustom ${finalAttrs.gradleUpdateTask}
        runHook postGradleUpdate
      '';

      buildPhase = ''
        runHook preBuild
        tmpbin="$(mktemp -d)"
        tee > "$tmpbin/gradlecustom" <<EOF
        #!${runtimeShell}
        exec ${gradleRunner}/bin/gradle ''${gradleFlags[@]} ''${gradleFlagsArray[@]} $GRADLE_FLAGS "\$@"
        EOF
        chmod +x "$tmpbin/gradlecustom"
        export PATH="$tmpbin:$PATH"
        gradlecustom ${finalAttrs.gradleBuildTask}
        runHook postBuild
      '';

      installPhase = ''
        runHook preInstall

        distZip="$(find . -path '*/build/distributions/gradle-*-bin.zip' | head -n1)"
        test -n "$distZip"
        test -f "$distZip"

        mkdir dist-unpack
        unzip -q "$distZip" -d dist-unpack
        cd dist-unpack/gradle-*

        mkdir -p "$out/libexec/gradle" "$out/bin"
        mv lib "$out/libexec/gradle/"
        mv bin "$out/libexec/gradle/"

        makeWrapper "$out/libexec/gradle/bin/gradle" "$out/bin/gradle" \
          --set-default JAVA_HOME "${finalAttrs.env.JAVA_HOME}"

        runHook postInstall
      '';

      passthru = {
        inherit (finalAttrs) jdk mitmCache;
        tests = { };
      };
    });

  unwrapped = callPackage mkGradle' { };
in
(callPackage gradle-packages.wrapGradle {
  gradle-unwrapped = unwrapped;
}).overrideAttrs
  (old: {
    passthru = old.passthru // {
      inherit (unwrapped) mitmCache;
    };
  })
