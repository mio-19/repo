{
  callPackage,
  fetchFromGitHub,
  gradle-packages,
  gradle_5_2_1,
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
      gradle_5_2_1,
      jdk11_headless,
      jdk8_headless,
      makeWrapper,
      runtimeShell,
      stdenv,
      unzip,
      ...
    }:
    let
      gradleRunner = gradle_5_2_1;
      gradleRunnerKotlinDeps = stdenv.mkDerivation (runnerAttrs: {
        pname = "gradle-5.3.1-runner-kotlin-deps";
        version = "1.3.21";

        src = ./.;

        nativeBuildInputs = [
          gradleRunner
          jdk11_headless
        ];

        mitmCache = gradleRunner.fetchDeps {
          inherit (runnerAttrs) pname;
          pkg = runnerAttrs.finalPackage;
          data = ./runner_deps.json;
          silent = false;
          useBwrap = false;
        };

        env.JAVA_HOME = jdk11_headless.passthru.home;

        gradleUpdateScript = ''
          runHook preBuild
          export HOME="$PWD/.home"
          export GRADLE_USER_HOME="$HOME/.gradle"
          export GRADLE_OPTS="-Xmx2048m -XX:MaxMetaspaceSize=1024m -Dfile.encoding=UTF-8 ''${GRADLE_OPTS:-}"
          mkdir -p "$GRADLE_USER_HOME" seed
          cat > "$GRADLE_USER_HOME/gradle.properties" <<EOF
          org.gradle.daemon=false
          org.gradle.jvmargs=-Xmx2048m -XX:MaxMetaspaceSize=1024m -Dfile.encoding=UTF-8
          EOF
          cd seed
          cat > settings.gradle <<'EOF'
          pluginManagement {
              repositories {
                  gradlePluginPortal()
                  mavenCentral()
              }
          }
          EOF
          cat > build.gradle <<'EOF'
          buildscript {
              repositories {
                  gradlePluginPortal()
                  mavenCentral()
              }
              dependencies {
                  classpath 'org.jetbrains.kotlin:kotlin-gradle-plugin:1.3.21'
                  classpath 'org.jetbrains.kotlin:kotlin-compiler-embeddable:1.3.21'
              }
          }
          EOF
          gradle --no-daemon --stacktrace help
          runHook postBuild
        '';

        buildPhase = ''
          runHook preBuild
          runHook postBuild
        '';

        installPhase = ''
          runHook preInstall
          mkdir -p "$out"
          runHook postInstall
        '';

        passthru = {
          inherit (runnerAttrs) mitmCache;
          fetchDeps = runnerAttrs.mitmCache.updateScript;
        };
      });
    in
    stdenv.mkDerivation (finalAttrs: {
      pname = "gradle-unwrapped";
      version = "5.3.1";

      src = fetchFromGitHub {
        owner = "gradle";
        repo = "gradle";
        tag = "v5.3.1";
        hash = "sha256-j6vpOEz+lncit1SeEBf2kKtCyJhLmME7lm38SFW1eA0=";
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

      patches = [ ];
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
        gradleRunnerKotlinM2="${gradleRunnerKotlinDeps.mitmCache}/https/plugins.gradle.org/m2/org/jetbrains"
        gradleRunnerKotlinCache="$gradleRunnerKotlinM2/kotlin"
        gradleRunnerCache="${gradleRunner.mitmCache}/https/plugins.gradle.org/m2"
        gradleRunnerClasspath="$gradleRunnerKotlinCache/kotlin-compiler-embeddable/1.3.21/kotlin-compiler-embeddable-1.3.21.jar:$gradleRunnerKotlinCache/kotlin-reflect/1.3.21/kotlin-reflect-1.3.21.jar:$gradleRunnerKotlinCache/kotlin-script-runtime/1.3.21/kotlin-script-runtime-1.3.21.jar:$gradleRunnerKotlinCache/kotlin-stdlib/1.3.21/kotlin-stdlib-1.3.21.jar:$gradleRunnerKotlinCache/kotlin-stdlib-common/1.3.21/kotlin-stdlib-common-1.3.21.jar:$gradleRunnerKotlinM2/intellij/deps/trove4j/1.0.20181211/trove4j-1.0.20181211.jar:$gradleRunnerKotlinM2/annotations/13.0/annotations-13.0.jar:$gradleRunnerCache/commons-logging/commons-logging/1.2/commons-logging-1.2.jar:${gradleRunner}/libexec/gradle/lib/plugins/commons-codec-1.11.jar:${gradleRunner}/libexec/gradle/lib/plugins/httpclient-4.5.6.jar:${gradleRunner}/libexec/gradle/lib/plugins/httpcore-4.4.10.jar:${gradleRunner}/libexec/gradle/lib/plugins/jsch-0.1.54.jar"
        export GRADLE_OPTS="-Xmx4096m -XX:MaxMetaspaceSize=2048m -Dfile.encoding=UTF-8 -Xbootclasspath/a:$gradleRunnerClasspath ''${GRADLE_OPTS:-}"
        cat > "$GRADLE_USER_HOME/gradle.properties" <<EOF
        org.gradle.daemon=false
        org.gradle.jvmargs=-Xmx4096m -XX:MaxMetaspaceSize=2048m -Dfile.encoding=UTF-8 -Xbootclasspath/a:$gradleRunnerClasspath
        systemProp.org.gradle.internal.http.connectionTimeout=30000
        systemProp.org.gradle.internal.http.socketTimeout=30000
        systemProp.http.keepAlive=false
        kotlin.compiler.execution.strategy=in-process
        kotlin.daemon.enabled=false
        kotlin.incremental=false
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
                substitute module('org.samba.jcifs:jcifs') with module('jcifs:jcifs:1.3.17')
                substitute module('org.jetbrains.kotlinx:kotlinx-metadata-jvm:0.0.4') with module('org.jetbrains.kotlinx:kotlinx-metadata-jvm:0.0.5')
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
        "--no-daemon"
        "--no-parallel"
        "--max-workers=1"
        "-PpromotionCommitId=v5.3.1"
        "-Pjava9Home=${jdk11_headless.passthru.home}"
        "-Djava9Home=${jdk11_headless.passthru.home}"
        "-Dfile.encoding=UTF-8"
        "-Dorg.gradle.internal.http.connectionTimeout=30000"
        "-Dorg.gradle.internal.http.socketTimeout=30000"
        "-Dhttp.keepAlive=false"
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
        replaceIfPresent() {
          local file="$1"
          local from="$2"
          local to="$3"
          local contents
          if [ ! -f "$file" ]; then
            return 0
          fi
          contents="$(cat "$file")"
          if [[ "$contents" == *"$from"* ]]; then
            substituteInPlace "$file" --replace-fail "$from" "$to"
          fi
        }

        replaceIfPresent buildSrc/subprojects/build/src/main/groovy/org/gradle/build/docs/dsl/source/GenerateDefaultImportsTask.java \
          'objectFactory.fileProperty()' \
          'getProject().getLayout().fileProperty()'
        replaceIfPresent buildSrc/subprojects/cleanup/src/main/kotlin/org/gradle/gradlebuild/testing/integrationtests/cleanup/EmptyDirectoryCheck.kt \
          'objects.directoryProperty()' \
          'project.layout.directoryProperty()'
        replaceIfPresent buildSrc/subprojects/cleanup/src/main/kotlin/org/gradle/gradlebuild/testing/integrationtests/cleanup/EmptyDirectoryCheck.kt \
          'objects.fileProperty()' \
          'project.layout.fileProperty()'
        replaceIfPresent buildSrc/subprojects/packaging/src/main/kotlin/org/gradle/gradlebuild/packaging/ApiMetadataPlugin.kt \
          'project.objects.fileProperty()' \
          'project.layout.fileProperty()'
        replaceIfPresent buildSrc/subprojects/packaging/src/main/kotlin/org/gradle/gradlebuild/packaging/ApiMetadataPlugin.kt \
          'classLoaderFactory.createIsolatedClassLoader("parameter names", DefaultClassPath.of(classpath.files))' \
          'classLoaderFactory.createIsolatedClassLoader(DefaultClassPath.of(classpath.files))'
        replaceIfPresent buildSrc/subprojects/packaging/src/main/kotlin/org/gradle/gradlebuild/packaging/ApiMetadataExtension.kt \
          'val includes = project.objects.listProperty<String>().empty()' \
          'val includes = project.objects.listProperty<String>().apply { set(emptyList()) }'
        replaceIfPresent buildSrc/subprojects/packaging/src/main/kotlin/org/gradle/gradlebuild/packaging/ApiMetadataExtension.kt \
          'val excludes = project.objects.listProperty<String>().empty()' \
          'val excludes = project.objects.listProperty<String>().apply { set(emptyList()) }'
        replaceIfPresent buildSrc/subprojects/packaging/src/main/kotlin/org/gradle/gradlebuild/packaging/ApiMetadataPlugin.kt \
          'include(extension.includes.get())' \
          'include(*extension.includes.get().toTypedArray())'
        replaceIfPresent buildSrc/subprojects/packaging/src/main/kotlin/org/gradle/gradlebuild/packaging/ApiMetadataPlugin.kt \
          'exclude(extension.excludes.get())' \
          'exclude(*extension.excludes.get().toTypedArray())'
        replaceIfPresent buildSrc/subprojects/packaging/src/main/kotlin/org/gradle/gradlebuild/packaging/ParameterNamesResourceTask.kt \
          'project.objects.fileProperty()' \
          'project.layout.fileProperty()'
        replaceIfPresent buildSrc/subprojects/packaging/src/main/kotlin/org/gradle/gradlebuild/packaging/ParameterNamesResourceTask.kt \
          'classLoaderFactory.createIsolatedClassLoader("parameter names", DefaultClassPath.of(classpath.files))' \
          'classLoaderFactory.createIsolatedClassLoader(DefaultClassPath.of(classpath.files))'
        replaceIfPresent buildSrc/subprojects/buildquality/src/main/kotlin/org/gradle/gradlebuild/buildquality/incubation/IncubatingApiAggregateReportTask.kt \
          'project.objects.fileProperty()' \
          'project.layout.fileProperty()'
        replaceIfPresent buildSrc/subprojects/buildquality/src/main/kotlin/org/gradle/gradlebuild/buildquality/incubation/IncubatingApiReportTask.kt \
          'project.objects.fileProperty()' \
          'project.layout.fileProperty()'
        replaceIfPresent buildSrc/subprojects/packaging/src/main/kotlin/org/gradle/gradlebuild/packaging/ShadedJar.kt \
          'project.objects.fileProperty()' \
          'project.layout.fileProperty()'
        replaceIfPresent buildSrc/subprojects/packaging/src/main/kotlin/org/gradle/gradlebuild/packaging/ShadedJar.kt \
          'val jarFile = project.layout.fileProperty()' \
          'val jarFile: RegularFileProperty = project.layout.fileProperty()'
        replaceIfPresent buildSrc/subprojects/packaging/src/main/kotlin/org/gradle/gradlebuild/packaging/ShadedJarPlugin.kt \
          'extensions.create<ShadedJarExtension>("shadedJar", objects, configurationToShade)' \
          'extensions.create<ShadedJarExtension>("shadedJar", this, configurationToShade)'
        replaceIfPresent buildSrc/subprojects/packaging/src/main/kotlin/org/gradle/gradlebuild/packaging/ShadedJarPlugin.kt \
          'open class ShadedJarExtension(objects: ObjectFactory, val shadedConfiguration: Configuration) {' \
          'open class ShadedJarExtension(project: Project, val shadedConfiguration: Configuration) {'
        replaceIfPresent buildSrc/subprojects/packaging/src/main/kotlin/org/gradle/gradlebuild/packaging/ShadedJarPlugin.kt \
          'val buildReceiptFile = objects.fileProperty()' \
          'val buildReceiptFile: org.gradle.api.file.RegularFileProperty = project.layout.fileProperty()'
        replaceIfPresent buildSrc/subprojects/packaging/src/main/kotlin/org/gradle/gradlebuild/packaging/ShadedJarPlugin.kt \
          'val keepPackages = objects.setProperty(String::class)' \
          'val keepPackages = project.objects.setProperty(String::class)'
        replaceIfPresent buildSrc/subprojects/packaging/src/main/kotlin/org/gradle/gradlebuild/packaging/ShadedJarPlugin.kt \
          'val unshadedPackages = objects.setProperty(String::class)' \
          'val unshadedPackages = project.objects.setProperty(String::class)'
        replaceIfPresent buildSrc/subprojects/packaging/src/main/kotlin/org/gradle/gradlebuild/packaging/ShadedJarPlugin.kt \
          'val ignoredPackages = objects.setProperty(String::class)' \
          'val ignoredPackages = project.objects.setProperty(String::class)'
        replaceIfPresent buildSrc/subprojects/integration-testing/src/main/kotlin/org/gradle/gradlebuild/test/integrationtests/DistributionTest.kt \
          'BinaryDistributions(project.objects)' \
          'BinaryDistributions(project)'
        replaceIfPresent buildSrc/subprojects/integration-testing/src/main/kotlin/org/gradle/gradlebuild/test/integrationtests/DistributionTest.kt \
          'LibsRepositoryEnvironmentProvider(project.objects)' \
          'LibsRepositoryEnvironmentProvider(project)'
        replaceIfPresent buildSrc/subprojects/integration-testing/src/main/kotlin/org/gradle/gradlebuild/test/integrationtests/DistributionTest.kt \
          'class LibsRepositoryEnvironmentProvider(objects: ObjectFactory)' \
          'class LibsRepositoryEnvironmentProvider(project: Project)'
        replaceIfPresent buildSrc/subprojects/integration-testing/src/main/kotlin/org/gradle/gradlebuild/test/integrationtests/DistributionTest.kt \
          'val dir = objects.directoryProperty()' \
          'val dir = project.layout.directoryProperty()'
        replaceIfPresent buildSrc/subprojects/integration-testing/src/main/kotlin/org/gradle/gradlebuild/test/integrationtests/DistributionTest.kt \
          'project.objects.directoryProperty()' \
          'project.layout.directoryProperty()'
        replaceIfPresent buildSrc/subprojects/integration-testing/src/main/kotlin/org/gradle/gradlebuild/test/integrationtests/DistributionTest.kt \
          'class BinaryDistributions(objects: ObjectFactory)' \
          'class BinaryDistributions(project: Project)'
        replaceIfPresent buildSrc/subprojects/integration-testing/src/main/kotlin/org/gradle/gradlebuild/test/integrationtests/DistributionTest.kt \
          'val distsDir = objects.directoryProperty()' \
          'val distsDir = project.layout.directoryProperty()'
        replaceIfPresent buildSrc/subprojects/integration-testing/src/main/kotlin/org/gradle/gradlebuild/test/integrationtests/DistributionTestingPlugin.kt \
          'objects.directoryProperty()' \
          'layout.directoryProperty()'
        replaceIfPresent buildSrc/subprojects/integration-testing/src/main/kotlin/org/gradle/gradlebuild/test/fixtures/IntTestImagePlugin.kt \
          'zipTree(allZip.archiveFile)' \
          'zipTree(allZip.archivePath)'
        replaceIfPresent buildSrc/subprojects/buildquality/src/main/kotlin/org/gradle/gradlebuild/buildquality/classycle/ClassycleExtension.kt \
          'project.objects.fileProperty()' \
          'project.layout.fileProperty()'
        replaceIfPresent subprojects/distributions/binary-compatibility.gradle \
          'patternLayout {' \
          'layout "pattern", {'
        replaceIfPresent subprojects/distributions/distributions.gradle \
          'destinationDirectory.set(rootProject.layout.buildDirectory.dir(rootProject.distsDirName))' \
          'destinationDir = rootProject.file("''${rootProject.buildDir}/''${rootProject.distsDirName}")'
        replaceIfPresent subprojects/distributions/distributions.gradle \
          "archiveClassifier.set('all')" \
          "classifier = 'all'"
        replaceIfPresent subprojects/distributions/distributions.gradle \
          "archiveClassifier.set('bin')" \
          "classifier = 'bin'"
        replaceIfPresent subprojects/distributions/distributions.gradle \
          "archiveClassifier.set('src')" \
          "classifier = 'src'"
        replaceIfPresent subprojects/distributions/distributions.gradle \
          'archiveFileName.set("outputs.zip")' \
          'archiveName = "outputs.zip"'
        replaceIfPresent buildSrc/subprojects/performance/src/main/groovy/org/gradle/testing/performance/generator/tasks/BuildBuilderGenerator.groovy \
          'objectFactory.directoryProperty()' \
          'project.layout.directoryProperty()'
        replaceIfPresent buildSrc/subprojects/configuration/src/main/kotlin/org/gradle/gradlebuild/dependencies/DependenciesMetadataRulesPlugin.kt \
          'require("1.4.01")' \
          'strictly("1.4.01")'
        replaceIfPresent buildSrc/subprojects/configuration/src/main/kotlin/org/gradle/gradlebuild/dependencies/DependenciesMetadataRulesPlugin.kt \
          'it.because("Gradle has trouble with the versioning scheme and pom redirects in higher versions")' \
          ""
        replaceIfPresent subprojects/native/src/main/java/org/gradle/internal/nativeintegration/filesystem/services/NativePlatformBackedSymlink.java \
          'import net.rubygrapefruit.platform.PosixFile;' \
          'import net.rubygrapefruit.platform.FileInfo;'
        replaceIfPresent subprojects/native/src/main/java/org/gradle/internal/nativeintegration/filesystem/services/NativePlatformBackedSymlink.java \
          'PosixFile.Type.Symlink' \
          'FileInfo.Type.Symlink'
        replaceIfPresent subprojects/logging/src/main/java/org/gradle/internal/logging/sink/AnsiConsoleUtil.java \
          'CLibrary.CLIBRARY.isatty(fileno)' \
          'CLibrary.isatty(fileno)'
        replaceIfPresent subprojects/core/src/main/java/org/gradle/internal/filewatch/jdk7/WatchServiceFileWatcherBacking.java \
          'import com.google.common.util.concurrent.ListeningExecutorService;' \
          'import com.google.common.util.concurrent.ListeningExecutorService;
        import com.google.common.util.concurrent.MoreExecutors;'
        replaceIfPresent subprojects/core/src/main/java/org/gradle/internal/filewatch/jdk7/WatchServiceFileWatcherBacking.java \
          $'            });\n            return fileWatcher;' \
          $'            }, MoreExecutors.directExecutor());\n            return fileWatcher;'
        replaceIfPresent subprojects/core/src/main/java/org/gradle/api/internal/tasks/userinput/DefaultUserInputHandler.java \
          'CharMatcher.JAVA_ISO_CONTROL.removeFrom(StringUtils.trim(input))' \
          'CharMatcher.javaIsoControl().removeFrom(StringUtils.trim(input))'
        replaceIfPresent buildSrc/subprojects/plugins/src/main/kotlin/gradlebuild/publish-public-libraries.gradle.kts \
          'archiveClassifier.set("sources")' \
          'classifier = "sources"'
        replaceIfPresent buildSrc/subprojects/plugins/src/main/kotlin/org/gradle/gradlebuild/unittestandcompile/UnitTestAndCompilePlugin.kt \
          'archiveVersion.set(baseVersion)' \
          'version = baseVersion'
        replaceIfPresent buildSrc/subprojects/plugins/src/main/kotlin/org/gradle/plugins/performance/PerformanceTestPlugin.kt \
          'destinationDirectory.set(buildDir)' \
          'destinationDir = buildDir'
        replaceIfPresent buildSrc/subprojects/plugins/src/main/kotlin/org/gradle/plugins/performance/PerformanceTestPlugin.kt \
          'archiveFileName.set("test-results-''${junitXmlDir.name}.zip")' \
          'archiveName = "test-results-''${junitXmlDir.name}.zip"'
        replaceIfPresent build.gradle.kts \
          '    id("com.gradle.build-scan")' \
          '    // build scans are disabled for the Gradle 4.10 source bootstrap'
        replaceIfPresent build.gradle.kts \
          'apply(plugin = "gradlebuild.buildscan")' \
          '// build scans are disabled for the Gradle 4.10 source bootstrap'
        replaceIfPresent buildSrc/build.gradle.kts \
          '        enableStricterValidation = true' \
          '        // stricter task validation is unavailable in the bootstrap Gradle'
        replaceIfPresent buildSrc/subprojects/buildquality/src/main/kotlin/org/gradle/gradlebuild/buildquality/TaskPropertyValidationPlugin.kt \
          '            validateTaskPropertiesForConfiguration(configurations["compile"])' \
          '            configurations.findByName("compile")?.let { validateTaskPropertiesForConfiguration(it) }'
        replaceIfPresent buildSrc/subprojects/buildquality/src/main/kotlin/org/gradle/gradlebuild/buildquality/TaskPropertyValidationPlugin.kt \
          '                enableStricterValidation = true' \
          '                // stricter task validation is unavailable in the bootstrap Gradle'
        replaceIfPresent build.gradle.kts \
          $'        val createBuildReceipt = tasks.named("createBuildReceipt", BuildReceipt::class.java)\n        val receiptFile = createBuildReceipt.map {\n            it.receiptFile\n        }\n        outgoing.artifact(receiptFile) {\n            builtBy(createBuildReceipt)\n        }' \
          $'        val createBuildReceipt = tasks.getByName("createBuildReceipt") as BuildReceipt\n        outgoing.artifact(createBuildReceipt.receiptFile) {\n            builtBy(createBuildReceipt)\n        }'
        replaceIfPresent subprojects/core/core.gradle.kts \
          $'tasks.classpathManifest {\n    optionalProjects = listOf("gradle-kotlin-dsl")\n}' \
          '(tasks.getByName("classpathManifest") as ClasspathManifest).optionalProjects = listOf("gradle-kotlin-dsl")'
        replaceIfPresent subprojects/core/core.gradle.kts \
          $'tasks.test {\n    setForkEvery(200)\n}' \
          '(tasks.getByName("test") as org.gradle.api.tasks.testing.Test).setForkEvery(200)'
        replaceIfPresent subprojects/core/core.gradle.kts \
          $'sourceSets.main {\n    output.dir(generatedResourcesDir, "builtBy" to pluginsManifest)\n}' \
          'sourceSets.getByName("main").output.dir(generatedResourcesDir, "builtBy" to pluginsManifest)'
        replaceIfPresent subprojects/core/core.gradle.kts \
          $'sourceSets.main {\n    output.dir(generatedResourcesDir, "builtBy" to implementationPluginsManifest)\n}' \
          'sourceSets.getByName("main").output.dir(generatedResourcesDir, "builtBy" to implementationPluginsManifest)'
        replaceIfPresent subprojects/launcher/launcher.gradle.kts \
          'project(it).tasks.jar.get().archivePath.name' \
          '(project(it).tasks.getByName("jar") as org.gradle.jvm.tasks.Jar).archivePath.name'
        replaceIfPresent subprojects/launcher/launcher.gradle.kts \
          'tasks.jar.get().manifest.attributes("Class-Path" to classpath)' \
          '(tasks.getByName("jar") as org.gradle.jvm.tasks.Jar).manifest.attributes("Class-Path" to classpath)'
        replaceIfPresent subprojects/launcher/launcher.gradle.kts \
          $'tasks.jar {\n    dependsOn(configureJar)\n    manifest.attributes("Main-Class" to "org.gradle.launcher.GradleMain")\n}' \
          $'(tasks.getByName("jar") as org.gradle.jvm.tasks.Jar).apply {\n    dependsOn(configureJar)\n    manifest.attributes("Main-Class" to "org.gradle.launcher.GradleMain")\n}'
        replaceIfPresent subprojects/launcher/launcher.gradle.kts \
          'launcherJar = tasks.jar.get().outputs.files' \
          'launcherJar = (tasks.getByName("jar") as org.gradle.jvm.tasks.Jar).outputs.files'
        substituteInPlace buildSrc/subprojects/packaging/src/main/kotlin/org/gradle/gradlebuild/packaging/MinifyPlugin.kt \
          --replace-fail \
            'attributes.attribute(minified, true)' \
            'attributes.attribute(minified, false)'
        substituteInPlace buildSrc/subprojects/packaging/src/main/kotlin/org/gradle/gradlebuild/packaging/ShadedJarPlugin.kt \
          --replace-fail \
            '.attribute(minified, true)' \
            '.attribute(minified, false)'
        substituteInPlace buildSrc/subprojects/kotlin-dsl/src/main/kotlin/build/GradleApiParameterNamesTransform.kt \
          --replace-fail \
            'from.attribute(artifactType, "jar").attribute(minified, true)' \
            'from.attribute(artifactType, "jar").attribute(minified, false)'
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
          "        if (name.startsWith(\"compileTest\") || name.startsWith(\"codenarc\") || name.startsWith(\"checkstyle\") || name == \"test\" || name == \"check\" || name.endsWith(\"Check\") || name == \"validateTaskProperties\") {" \
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
        inherit gradleRunnerKotlinDeps;
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
      inherit (unwrapped) mitmCache gradleRunnerKotlinDeps;
    };
  })
