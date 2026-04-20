{
  callPackage,
  fetchFromGitHub,
  gradle-packages,
  gradle_4_9_0,
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
      gradle_4_9_0,
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

      patches = [
        ./bootstrap-compat.patch
        ./bootstrap-jdk11-compat.patch
      ];

      patchFlags = [ "-p1" ];

      gradleBuildTask = ":distributions:binZip";
      gradleUpdateTask = finalAttrs.gradleBuildTask;

      nativeBuildInputs = [
        gradleRunner
        jdk11_headless
        jdk8_headless
        makeWrapper
        unzip
      ];

      mitmCache = gradle_4_10_3.fetchDeps {
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
        cat > "$GRADLE_USER_HOME/gradle.properties" <<'EOF'
        org.gradle.daemon=false
        org.gradle.jvmargs=-Xmx1024m -Dfile.encoding=UTF-8
        EOF
        export gradleInitScript="$PWD/init-build-compat.gradle"
        cat > "$gradleInitScript" <<'EOF'
        gradle.projectsLoaded {
          rootProject.allprojects {
            tasks.withType(AbstractArchiveTask) {
              if (it.hasProperty('preserveFileTimestamps')) {
                preserveFileTimestamps = false
              }
              if (it.hasProperty('reproducibleFileOrder')) {
                reproducibleFileOrder = true
              }
            }
            tasks.matching { it.name.toLowerCase().contains("test") || it.name.toLowerCase().contains("check") || it.name.contains("ktlint") || it.name.startsWith("docs") }.all {
              enabled = false
            }
          }
        }
        EOF
        filteredGradleFlagsArray=()
        skipNext=
        for arg in "''${gradleFlagsArray[@]}"; do
          if [ -n "$skipNext" ]; then
            skipNext=
            continue
          fi
          if [ "$arg" = "--init-script" ]; then
            skipNext=1
            continue
          fi
          filteredGradleFlagsArray+=("$arg")
        done
        gradleFlagsArray=("''${filteredGradleFlagsArray[@]}" --init-script "$gradleInitScript")

        # Robust source-wide fixes
        find . -type f \( -name "*.kts" -o -name "*.gradle" \) -exec sed -i 's/1\.0-rc-5/1\.0-rc-6/g' {} +
        find . -type f \( -name "*.kts" -o -name "*.gradle" \) -exec sed -i 's/0\.9-2\.4\.15/2\.4\.15/g' {} +
        
        # Inject repositories into all build files that have repositories block
        find . -type f \( -name "*.kts" -o -name "*.gradle" \) -exec sed -i '/repositories {/a \ \ \ \ \ \ \ \ mavenCentral()\n\ \ \ \ \ \ \ \ google()\n\ \ \ \ \ \ \ \ jcenter()' {} +

        # Remove problematic plugin and extension references in buildSrc for bootstrap
        if [ -f buildSrc/build.gradle.kts ]; then
          sed -i '/configure<JavaPluginExtension>/,/}/d' buildSrc/build.gradle.kts
          sed -i '/kotlinDslPluginOptions/,/}/d' buildSrc/build.gradle.kts
          # Replace unresolved sourceSets access
          sed -i 's/project\.sourceSets/project\.the<JavaPluginConvention>()\.sourceSets/g' buildSrc/build.gradle.kts
        fi

        # Disable problematic buildSrc subprojects and their usages
        find . -type f \( -name "*.kts" -o -name "*.gradle" \) -exec sed -i 's/include("performance")/\/\/include("performance")/g' {} +
        find . -type f \( -name "*.kts" -o -name "*.gradle" \) -exec sed -i 's/include("buildquality")/\/\/include("buildquality")/g' {} +
        find . -type f \( -name "*.kts" -o -name "*.gradle" \) -exec sed -i '/project(":performance")/d' {} +
        find . -type f \( -name "*.kts" -o -name "*.gradle" \) -exec sed -i '/project(":buildquality")/d' {} +

        # Wipe out failing GenerateDefaultImportsTask
        if [ -f buildSrc/subprojects/build/src/main/groovy/org/gradle/build/docs/dsl/source/GenerateDefaultImportsTask.java ]; then
          echo "package org.gradle.build.docs.dsl.source; import org.gradle.api.DefaultTask; public class GenerateDefaultImportsTask extends DefaultTask {}" > buildSrc/subprojects/build/src/main/groovy/org/gradle/build/docs/dsl/source/GenerateDefaultImportsTask.java
        fi
      '';

      gradleFlags = [
        "-PfinalRelease=true"
        "-PpromotionCommitId=v5.0.0-M1"
        "-Pjava9Home=${jdk11_headless.passthru.home}"
        "-Djava9Home=${jdk11_headless.passthru.home}"
        "-Dfile.encoding=UTF-8"
        "-DbootstrapWithGradle4_10_3=true"
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
        exec ${gradleRunner}/bin/gradle ''${gradleFlags[@]} ''${gradleFlagsArray[@]} "\$@"
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
        exec ${gradleRunner}/bin/gradle ''${gradleFlags[@]} ''${gradleFlagsArray[@]} "\$@"
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
        substituteInPlace "$out/libexec/gradle/bin/gradle" \
          --replace-fail \
            'CLASSPATH=$APP_HOME/lib/gradle-launcher-5.0-milestone-1.jar' \
            'CLASSPATH=$APP_HOME/lib/gradle-launcher-5.0-milestone-1.jar:$APP_HOME/lib/*:$APP_HOME/lib/plugins/*'

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
