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

      gradleBuildTask = ":distributions:binZip";
      gradleUpdateTask = "${finalAttrs.gradleBuildTask} --stacktrace";

      nativeBuildInputs = [
        gradleRunner
        jdk11_headless
        jdk8_headless
        makeWrapper
        unzip
      ];

      patches = [
        ../../libs-deprecated/gradle_5_0_M1/bootstrap-compat.patch
        ../../libs-deprecated/gradle_5_0_M1/bootstrap-jdk11-compat.patch
      ];
      patchFlags = [ "-p1" ];

      mitmCache = gradleRunner.fetchDeps {
        inherit (finalAttrs) pname;
        pkg = finalAttrs.finalPackage;
        data = ./deps.json;
        silent = false;
        useBwrap = false;
      };

      __darwinAllowLocalNetworking = true;

      jdk = jdk11_headless;
      env.JAVA_HOME = jdk11_headless.passthru.home;

      preBuild = ''
        export HOME="$PWD/.home"
        export GRADLE_USER_HOME="$HOME/.gradle"
        export LANG=C.UTF-8
        export LC_ALL=C.UTF-8
        mkdir -p "$GRADLE_USER_HOME"
        gradleRunnerClasspath="${gradleRunner}/libexec/gradle/lib/plugins/commons-logging-1.2.jar:${gradleRunner}/libexec/gradle/lib/plugins/httpclient-4.5.5.jar:${gradleRunner}/libexec/gradle/lib/plugins/httpcore-4.4.9.jar:${gradleRunner}/libexec/gradle/lib/plugins/jsch-0.1.54.jar"
        export GRADLE_OPTS="-Xmx4096m -Dfile.encoding=UTF-8 -Xbootclasspath/a:$gradleRunnerClasspath ''${GRADLE_OPTS:-}"
        cat > "$GRADLE_USER_HOME/gradle.properties" <<EOF
        org.gradle.daemon=false
        kotlin.compiler.execution.strategy=in-process
        kotlin.daemon.enabled=false
        EOF
        export gradleInitScript="$PWD/init-build-compat.gradle"
        cat > "$gradleInitScript" <<'EOF'
        gradle.projectsLoaded {
          rootProject.allprojects {
            repositories {
              mavenCentral()
            }
            dependencies {
              components {
                withModule('org.codehaus.groovy:groovy-all') {
                  allVariants {
                    withDependencies {
                      removeAll { it.group == 'org.apache.ivy' || it.group == 'org.testng' }
                    }
                  }
                }
              }
            }
            configurations.all {
              exclude group: 'org.sonatype.sisu', module: 'sisu-inject-plexus'
              resolutionStrategy.dependencySubstitution {
                substitute module('org.gradle.groovy:groovy-all') with module('org.codehaus.groovy:groovy-all:2.4.15')
                substitute module('org.samba.jcifs:jcifs') with module('jcifs:jcifs:1.3.17')
                substitute module('org.jetbrains.kotlin:kotlin-stdlib-jdk8') with module('org.jetbrains.kotlin:kotlin-stdlib-jdk8:1.3.0')
                substitute module('org.jetbrains.kotlin:kotlin-reflect') with module('org.jetbrains.kotlin:kotlin-reflect:1.3.0')
                substitute module('org.jetbrains.kotlin:kotlin-script-runtime') with module('org.jetbrains.kotlin:kotlin-script-runtime:1.3.0')
                substitute module('org.jetbrains.kotlin:kotlin-compiler-embeddable') with module('org.jetbrains.kotlin:kotlin-compiler-embeddable:1.3.0')
                substitute module('org.jetbrains.kotlin:kotlin-sam-with-receiver-compiler-plugin') with module('org.jetbrains.kotlin:kotlin-sam-with-receiver-compiler-plugin:1.3.0')
              }
              resolutionStrategy.force 'org.apache.ivy:ivy:2.3.0', 'org.testng:testng:6.3.1'
            }
            tasks.withType(AbstractArchiveTask) {
              if (it.hasProperty('preserveFileTimestamps')) {
                preserveFileTimestamps = false
              }
              if (it.hasProperty('reproducibleFileOrder')) {
                reproducibleFileOrder = true
              }
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
      '';

      gradleFlags = [
        "-x"
        ":docs:distDocs"
        "-x"
        ":docs:samples"
        "--no-parallel"
        "--max-workers=1"
        "-PmilestoneNumber=1"
        "-PpromotionCommitId=v5.0.0-M1"
        "-Pjava9Home=${jdk11_headless.passthru.home}"
        "-Djava9Home=${jdk11_headless.passthru.home}"
        "-Dfile.encoding=UTF-8"
      ];

      postPatch = ''
                rm -f gradle/verification-metadata.xml
                rm -rf gradle/wrapper .teamcity/.mvn/wrapper
                find . -name "*.jar" -print0 | xargs -0 rm -f
                substituteInPlace settings.gradle.kts \
                  --replace-fail \
                    'apply(from = "gradle/shared-with-buildSrc/build-cache-configuration.settings.gradle.kts")' \
                    '// build cache configuration is disabled for the Nix source bootstrap'
                substituteInPlace buildSrc/settings.gradle.kts \
                  --replace-fail \
                    'apply(from = "../gradle/shared-with-buildSrc/build-cache-configuration.settings.gradle.kts")' \
                    '// build cache configuration is disabled for the Nix source bootstrap'
                substituteInPlace buildSrc/build.gradle.kts \
                  --replace-fail \
                    '        compile(gradleApi())' \
                    '        compile(gradleApi())
                        compile("org.slf4j:slf4j-api:1.7.16")
                        compile("javax.inject:javax.inject:1")
                        compile("com.google.code.findbugs:jsr305:2.0.1")
                        compile("net.rubygrapefruit:native-platform:0.14")'
        substituteInPlace buildSrc/subprojects/build/src/main/groovy/org/gradle/build/docs/dsl/source/GenerateDefaultImportsTask.java \
          --replace-fail \
            'objectFactory.fileProperty()' \
            'getProject().getLayout().fileProperty()'
        substituteInPlace buildSrc/subprojects/cleanup/src/main/kotlin/org/gradle/gradlebuild/testing/integrationtests/cleanup/EmptyDirectoryCheck.kt \
          --replace-fail \
            'objects.directoryProperty()' \
            'project.layout.directoryProperty()' \
          --replace-fail \
            'objects.fileProperty()' \
            'project.layout.fileProperty()'
        substituteInPlace buildSrc/subprojects/packaging/src/main/kotlin/org/gradle/gradlebuild/packaging/ApiMetadataPlugin.kt \
          --replace-fail \
            'project.objects.fileProperty()' \
            'project.layout.fileProperty()' \
          --replace-fail \
            'classLoaderFactory.createIsolatedClassLoader("parameter names", DefaultClassPath.of(classpath.files))' \
            'classLoaderFactory.createIsolatedClassLoader(DefaultClassPath.of(classpath.files))'
        substituteInPlace buildSrc/subprojects/packaging/src/main/kotlin/org/gradle/gradlebuild/packaging/ShadedJar.kt \
          --replace-fail \
            'project.objects.fileProperty()' \
            'project.layout.fileProperty()' \
          --replace-fail \
            'val jarFile = project.layout.fileProperty()' \
            'val jarFile: RegularFileProperty = project.layout.fileProperty()'
        substituteInPlace buildSrc/subprojects/packaging/src/main/kotlin/org/gradle/gradlebuild/packaging/ShadedJarPlugin.kt \
          --replace-fail \
            'extensions.create<ShadedJarExtension>("shadedJar", objects, configurationToShade)' \
            'extensions.create<ShadedJarExtension>("shadedJar", this, configurationToShade)' \
          --replace-fail \
            'open class ShadedJarExtension(objects: ObjectFactory, val shadedConfiguration: Configuration) {' \
            'open class ShadedJarExtension(project: Project, val shadedConfiguration: Configuration) {' \
          --replace-fail \
            'val buildReceiptFile = objects.fileProperty()' \
            'val buildReceiptFile: org.gradle.api.file.RegularFileProperty = project.layout.fileProperty()' \
          --replace-fail \
            'val keepPackages = objects.setProperty(String::class)' \
            'val keepPackages = project.objects.setProperty(String::class)' \
          --replace-fail \
            'val unshadedPackages = objects.setProperty(String::class)' \
            'val unshadedPackages = project.objects.setProperty(String::class)' \
          --replace-fail \
            'val ignoredPackages = objects.setProperty(String::class)' \
            'val ignoredPackages = project.objects.setProperty(String::class)'
        substituteInPlace buildSrc/subprojects/integration-testing/src/main/kotlin/org/gradle/gradlebuild/test/integrationtests/DistributionTest.kt \
          --replace-fail \
            'BinaryDistributions(project.objects)' \
            'BinaryDistributions(project)' \
          --replace-fail \
            'LibsRepositoryEnvironmentProvider(project.objects)' \
            'LibsRepositoryEnvironmentProvider(project)' \
          --replace-fail \
            'class LibsRepositoryEnvironmentProvider(objects: ObjectFactory)' \
            'class LibsRepositoryEnvironmentProvider(project: Project)' \
          --replace-fail \
            'val dir = objects.directoryProperty()' \
            'val dir = project.layout.directoryProperty()' \
          --replace-fail \
            'project.objects.directoryProperty()' \
            'project.layout.directoryProperty()' \
          --replace-fail \
            'class BinaryDistributions(objects: ObjectFactory)' \
            'class BinaryDistributions(project: Project)' \
          --replace-fail \
            'val distsDir = objects.directoryProperty()' \
            'val distsDir = project.layout.directoryProperty()'
        substituteInPlace buildSrc/subprojects/integration-testing/src/main/kotlin/org/gradle/gradlebuild/test/integrationtests/DistributionTestingPlugin.kt \
          --replace-fail \
            'objects.directoryProperty()' \
            'layout.directoryProperty()'
        substituteInPlace buildSrc/subprojects/buildquality/src/main/kotlin/org/gradle/gradlebuild/buildquality/classycle/ClassycleExtension.kt \
          --replace-fail \
            'project.objects.fileProperty()' \
            'project.layout.fileProperty()'
        substituteInPlace subprojects/distributions/binary-compatibility.gradle \
          --replace-fail \
            'patternLayout {' \
            'layout "pattern", {'
        substituteInPlace buildSrc/subprojects/performance/src/main/groovy/org/gradle/testing/performance/generator/tasks/BuildBuilderGenerator.groovy \
          --replace-fail \
            'objectFactory.directoryProperty()' \
            'project.layout.directoryProperty()'
        substituteInPlace buildSrc/subprojects/configuration/src/main/kotlin/org/gradle/gradlebuild/dependencies/DependenciesMetadataRulesPlugin.kt \
          --replace-fail \
            'require("1.4.01")' \
            'strictly("1.4.01")' \
          --replace-fail \
            'it.because("Gradle has trouble with the versioning scheme and pom redirects in higher versions")' \
            ""
        substituteInPlace subprojects/native/src/main/java/org/gradle/internal/nativeintegration/filesystem/services/NativePlatformBackedSymlink.java \
          --replace-fail \
            'import net.rubygrapefruit.platform.PosixFile;' \
            'import net.rubygrapefruit.platform.FileInfo;' \
          --replace-fail \
            'PosixFile.Type.Symlink' \
            'FileInfo.Type.Symlink'
        substituteInPlace subprojects/logging/src/main/java/org/gradle/internal/logging/sink/AnsiConsoleUtil.java \
          --replace-fail \
            'CLibrary.CLIBRARY.isatty(fileno)' \
            'CLibrary.isatty(fileno)'
        for sourceFile in \
          subprojects/core-api/src/main/java/org/gradle/api/tasks/util/internal/CachingPatternSpecFactory.java \
          subprojects/logging/src/main/java/org/gradle/internal/logging/console/Cursor.java \
          subprojects/tooling-api/src/main/java/org/gradle/tooling/internal/gradle/DefaultGradlePublication.java \
          subprojects/workers/src/main/java/org/gradle/workers/internal/DaemonForkOptions.java
        do
          substituteInPlace "$sourceFile" \
            --replace-fail \
              'import com.google.common.base.Objects;' \
              'import com.google.common.base.MoreObjects;
        import com.google.common.base.Objects;' \
            --replace-fail \
              'Objects.toStringHelper' \
              'MoreObjects.toStringHelper'
        done
        substituteInPlace subprojects/core/src/main/java/org/gradle/internal/filewatch/jdk7/WatchServiceFileWatcherBacking.java \
          --replace-fail \
            'import com.google.common.util.concurrent.ListeningExecutorService;' \
            'import com.google.common.util.concurrent.ListeningExecutorService;
        import com.google.common.util.concurrent.MoreExecutors;' \
          --replace-fail \
            $'            });\n            return fileWatcher;' \
            $'            }, MoreExecutors.directExecutor());\n            return fileWatcher;'
        substituteInPlace subprojects/core/src/main/java/org/gradle/api/internal/tasks/userinput/DefaultUserInputHandler.java \
          --replace-fail \
            'CharMatcher.JAVA_ISO_CONTROL.removeFrom(StringUtils.trim(input))' \
            'CharMatcher.javaIsoControl().removeFrom(StringUtils.trim(input))'
        printf '%s\n' \
          "" \
          "allprojects {" \
          "    repositories {" \
          "        maven {" \
          "            name = \"Groovy libs\"" \
          "            url = uri(\"https://groovy.jfrog.io/artifactory/libs-release/\")" \
          "        }" \
          "        maven {" \
          "            name = \"Appodeal\"" \
          "            url = uri(\"https://artifactory.appodeal.com/appodeal-public/\")" \
          "        }" \
          "    }" \
          "    configurations.all {" \
          "        resolutionStrategy.dependencySubstitution {" \
          "            substitute(module(\"org.gradle.groovy:groovy-all\")).with(module(\"org.codehaus.groovy:groovy-all:2.4.15\"))" \
          "        }" \
          "    }" \
          "    tasks.all {" \
          "        if (name.startsWith(\"compileTest\") || name == \"test\" || name == \"check\" || name.endsWith(\"Check\") || name == \"validateTaskProperties\") {" \
          "            enabled = false" \
          "        }" \
          "    }" \
          "}" >> buildSrc/build.gradle.kts
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

        makeWrapper "$out/libexec/gradle/bin/gradle" "$out/bin/gradle" \
          --set-default JAVA_HOME "${finalAttrs.env.JAVA_HOME}"

        runHook postInstall
      '';

      passthru = {
        inherit (finalAttrs) jdk mitmCache;
        tests = { };
        fetchDeps = finalAttrs.mitmCache.updateScript;
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
