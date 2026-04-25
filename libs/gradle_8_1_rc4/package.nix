{
  temurin-bin-8,
  temurin-bin-11,
  temurin-bin-17,
  jdk21_headless,
  gradle_8_1_20230203,
  gradle-from-source,
  mergeLock,
}:
gradle-from-source {
  version = "8.1.0-RC4";
  hash = "sha256-BiyNOrNP1uF5obGoIsH+vagULOILclKQ6gK9W73gLnY=";
  lockFile = mergeLock [
    gradle_8_1_20230203.unwrapped.passthru.lockFile
    ./gradle.lock
  ];
  defaultJava = jdk21_headless;
  buildJdk = temurin-bin-11;
  javaToolchains = [
    temurin-bin-8
    temurin-bin-11
    temurin-bin-17
  ];
  bootstrapGradle = gradle_8_1_20230203;
  patches = [
    ./internal-integ-testing-bootstrap.patch
  ];
  postPatch = ''
    substituteInPlace \
      build-logic/jvm/src/main/kotlin/gradlebuild.unittest-and-compile.gradle.kts \
      build-logic-commons/code-quality-rules/build.gradle.kts \
      build-logic-commons/commons/build.gradle.kts \
      build-logic-commons/commons/src/main/kotlin/common.kt \
      build-logic-commons/gradle-plugin/build.gradle.kts \
      --replace-fail 'languageVersion = JavaLanguageVersion.of(11)' 'languageVersion.set(JavaLanguageVersion.of(11))' \
      --replace-fail 'vendor = JvmVendorSpec.ADOPTIUM' 'vendor.set(JvmVendorSpec.ADOPTIUM)'
    substituteInPlace build-logic-commons/gradle-plugin/src/main/kotlin/gradlebuild.build-logic.kotlin-dsl-gradle-plugin.gradle.kts \
      --replace-fail '        allWarningsAsErrors = false' '        allWarningsAsErrors.set(false)' \
      --replace-fail '    failOnWarning = true' '    failOnWarning.set(true)' \
      --replace-fail '    enableStricterValidation = true' '    enableStricterValidation.set(true)'
    substituteInPlace build-logic-commons/gradle-plugin/src/main/kotlin/gradlebuild.ci-reporting.gradle.kts \
      --replace-fail '    projectState.projectBuildDir = buildDir' '    projectState.projectBuildDir.set(layout.buildDirectory)' \
      --replace-fail '    projectState.projectPath = path' '    projectState.projectPath.set(path)' \
      --replace-fail '    projectState.reportOnly = testFilesCleanup.reportOnly' '    projectState.reportOnly.set(testFilesCleanup.reportOnly)'
    substituteInPlace build-logic-commons/gradle-plugin/src/main/kotlin/gradlebuild.code-quality.gradle.kts \
      --replace-fail $'    configDirectory = rules.elements.map {\n        projectDirectory.dir(it.single().asFile.absolutePath).dir("checkstyle")\n    }' $'    configDirectory.set(rules.elements.map {\n        projectDirectory.dir(it.single().asFile.absolutePath).dir("checkstyle")\n    })' \
      --replace-fail '            reports.xml.outputLocation = checkstyle.reportsDir.resolve("''${this@all.name}-groovy.xml")' '            reports.xml.outputLocation.set(layout.file(provider { checkstyle.reportsDir.resolve("''${this@all.name}-groovy.xml") }))'
    substituteInPlace build-logic-commons/gradle-plugin/src/main/kotlin/gradlebuild/BuildScanInfoCollectingServices.kt \
      --replace-fail '                parameters.monitoredTaskPaths = allTasks.filter(taskFilter).map { if (isInBuildLogic) ":build-logic''${it.path}" else it.path }.toSet()' '                parameters.monitoredTaskPaths.set(allTasks.filter(taskFilter).map { if (isInBuildLogic) ":build-logic''${it.path}" else it.path }.toSet())'
    substituteInPlace build-logic-commons/gradle-plugin/src/main/kotlin/gradlebuild/testcleanup/TestFilesCleanupRootPlugin.kt \
      --replace-fail '                parameters.rootBuildDir = project.buildDir' '                parameters.rootBuildDir.set(project.layout.buildDirectory)' \
      --replace-fail '                parameters.testPathToBinaryResultsDirs = allTasks.filterIsInstance<Test>().associate { it.path to it.binaryResultsDirectory.get().asFile }' '                parameters.testPathToBinaryResultsDirs.putAll(allTasks.filterIsInstance<Test>().associate { it.path to it.binaryResultsDirectory.get().asFile })' \
      --replace-fail $'                parameters.taskPathToReports = globalExtension.taskPathToReports.map { taskPathToReportsInExtension ->\n                    (taskPathToReportsInExtension.keys + taskPathToReports.keys).associateWith {\n                        taskPathToReportsInExtension.getOrDefault(it, emptyList()) + taskPathToReports.getOrDefault(it, emptyList())\n                    }\n                }' $'                parameters.taskPathToReports.set(globalExtension.taskPathToReports.map { taskPathToReportsInExtension ->\n                    (taskPathToReportsInExtension.keys + taskPathToReports.keys).associateWith {\n                        taskPathToReportsInExtension.getOrDefault(it, emptyList()) + taskPathToReports.getOrDefault(it, emptyList())\n                    }\n                })'
    substituteInPlace build-logic/lifecycle/src/main/kotlin/gradlebuild.lifecycle.gradle.kts \
      --replace-fail '            parameters.timeoutMillis = determineTimeoutMillis()' '            parameters.timeoutMillis.set(determineTimeoutMillis())' \
      --replace-fail '            parameters.projectDirectory = layout.projectDirectory' '            parameters.projectDirectory.set(layout.projectDirectory)'
    substituteInPlace build-logic/lifecycle/src/main/kotlin/gradlebuild.teamcity-import-test-data.gradle.kts \
      --replace-fail $'            parameters.testTaskPathToJUnitXmlLocation = allTasks.filterIsInstance<Test>().associate {\n                it.path to gradleRootDir.relativize(it.reports.junitXml.outputLocation.asFile.get().toPath()).toString()\n            }' $'            parameters.testTaskPathToJUnitXmlLocation.set(allTasks.filterIsInstance<Test>().associate {\n                it.path to gradleRootDir.relativize(it.reports.junitXml.outputLocation.asFile.get().toPath()).toString()\n            })'
    substituteInPlace build-logic/build-update-utils/src/main/kotlin/gradlebuild.update-init-template-versions.gradle.kts \
      --replace-fail $'        libraryVersionFile = layout.projectDirectory.file(\n            "src/main/resources/org/gradle/buildinit/tasks/templates/library-versions.properties"\n        )' $'        libraryVersionFile.set(layout.projectDirectory.file(\n            "src/main/resources/org/gradle/buildinit/tasks/templates/library-versions.properties"\n        ))'
    substituteInPlace build-logic/build-update-utils/src/main/kotlin/gradlebuild.update-versions.gradle.kts \
      --replace-fail '    releasedVersionsFile = releasedVersionsFile()' '    releasedVersionsFile.set(releasedVersionsFile())' \
      --replace-fail $'    currentReleasedVersion = ReleasedVersion(\n        project.findProperty("currentReleasedVersion").toString(),\n        project.findProperty("currentReleasedVersionBuildTimestamp").toString()\n    )' $'    currentReleasedVersion.set(ReleasedVersion(\n        project.findProperty("currentReleasedVersion").toString(),\n        project.findProperty("currentReleasedVersionBuildTimestamp").toString()\n    ))' \
      --replace-fail $'    currentReleasedVersion = project.provider {\n        val jsonText = URL("https://services.gradle.org/versions/nightly").readText()\n        println(jsonText)\n        val versionInfo = Gson().fromJson(jsonText, VersionBuildTimeInfo::class.java)\n        ReleasedVersion(versionInfo.version, versionInfo.buildTime)\n    }' $'    currentReleasedVersion.set(project.provider {\n        val jsonText = URL("https://services.gradle.org/versions/nightly").readText()\n        println(jsonText)\n        val versionInfo = Gson().fromJson(jsonText, VersionBuildTimeInfo::class.java)\n        ReleasedVersion(versionInfo.version, versionInfo.buildTime)\n    })' \
      --replace-fail '    comment = " Generated - Update by running `./gradlew updateAgpVersions`"' '    comment.set(" Generated - Update by running `./gradlew updateAgpVersions`")' \
      --replace-fail '    minimumSupportedMinor = "7.3"' '    minimumSupportedMinor.set("7.3")' \
      --replace-fail '    fetchNightly = false' '    fetchNightly.set(false)' \
      --replace-fail '    propertiesFile = layout.projectDirectory.file("gradle/dependency-management/agp-versions.properties")' '    propertiesFile.set(layout.projectDirectory.file("gradle/dependency-management/agp-versions.properties"))'
    substituteInPlace build-logic/module-identity/src/main/kotlin/gradlebuild.module-identity.gradle.kts \
      --replace-fail $'    moduleIdentity.releasedVersions = provider {\n        ReleasedVersionsDetails(\n            moduleIdentity.version.get().baseVersion,\n            releasedVersionsFile()\n        )\n    }' $'    moduleIdentity.releasedVersions.set(provider {\n        ReleasedVersionsDetails(\n            moduleIdentity.version.get().baseVersion,\n            releasedVersionsFile()\n        )\n    })' \
      --replace-fail '            buildTimestampFromBuildReceipt = buildTimestampFromBuildReceipt()' '            buildTimestampFromBuildReceipt.set(buildTimestampFromBuildReceipt())' \
      --replace-fail '            buildTimestampFromGradleProperty = buildTimestamp' '            buildTimestampFromGradleProperty.set(buildTimestamp)' \
      --replace-fail '            runningOnCi = buildRunningOnCi' '            runningOnCi.set(buildRunningOnCi)' \
      --replace-fail '            runningInstallTask = provider { isRunningInstallTask() }' '            runningInstallTask.set(provider { isRunningInstallTask() })' \
      --replace-fail '            runningDocsTestTask = provider { isRunningDocsTestTask() }' '            runningDocsTestTask.set(provider { isRunningDocsTestTask() })' \
      --replace-fail '            ignoreIncomingBuildReceipt = project.ignoreIncomingBuildReceipt' '            ignoreIncomingBuildReceipt.set(project.ignoreIncomingBuildReceipt)' \
      --replace-fail $'            buildReceiptFileContents = repoRoot()\n                .dir("incoming-distributions")\n                .file(BuildReceipt.buildReceiptFileName)\n                .let(providers::fileContents)\n                .asText' $'            buildReceiptFileContents.set(repoRoot()\n                .dir("incoming-distributions")\n                .file(BuildReceipt.buildReceiptFileName)\n                .let(providers::fileContents)\n                .asText)'
    substituteInPlace build-logic/module-identity/src/main/kotlin/gradlebuild/identity/extension/ModuleIdentityExtension.kt \
      --replace-fail '            this.version = this@ModuleIdentityExtension.version.map { it.version }' '            this.version.set(this@ModuleIdentityExtension.version.map { it.version })' \
      --replace-fail '            this.baseVersion = this@ModuleIdentityExtension.version.map { it.baseVersion.version }' '            this.baseVersion.set(this@ModuleIdentityExtension.version.map { it.baseVersion.version })' \
      --replace-fail '            this.snapshot = this@ModuleIdentityExtension.snapshot' '            this.snapshot.set(this@ModuleIdentityExtension.snapshot)' \
      --replace-fail '            this.promotionBuild = this@ModuleIdentityExtension.promotionBuild' '            this.promotionBuild.set(this@ModuleIdentityExtension.promotionBuild)' \
      --replace-fail '            this.commitId = project.buildCommitId' '            this.commitId.set(project.buildCommitId)' \
      --replace-fail '            this.receiptFolder = project.layout.buildDirectory.dir("generated-resources/build-receipt")' '            this.receiptFolder.set(project.layout.buildDirectory.dir("generated-resources/build-receipt"))'
    substituteInPlace build-logic/module-identity/src/main/kotlin/gradlebuild/identity/tasks/BuildReceipt.kt \
      --replace-fail '        buildTimestamp = provider.map { buildTimestampString -> timestampFormat.parse(buildTimestampString) }' '        buildTimestamp.set(provider.map { buildTimestampString -> timestampFormat.parse(buildTimestampString) })'
    substituteInPlace build-logic/cleanup/src/main/kotlin/gradlebuild.cleanup.gradle.kts \
      --replace-fail '    parameters.rootProjectDir = repoRoot()' '    parameters.rootProjectDir.set(repoRoot())'
    substituteInPlace build-logic/profiling/src/main/kotlin/gradlebuild.jmh.gradle.kts \
      --replace-fail '    includeTests = false' '    includeTests.set(false)' \
      --replace-fail '    resultFormat = "CSV"' '    resultFormat.set("CSV")' \
      --replace-fail '    csv = tasks.jmh.map { layout.buildDirectory.file("results/jmh/results.csv").get() }' '    csv.set(tasks.jmh.map { layout.buildDirectory.file("results/jmh/results.csv").get() })' \
      --replace-fail '    destination = layout.buildDirectory.dir("reports/jmh-html")' '    destination.set(layout.buildDirectory.dir("reports/jmh-html"))'
    substituteInPlace build-logic/integration-testing/src/main/kotlin/gradlebuild.distribution-testing.gradle.kts \
      --replace-fail '    parameters.gradleVersion = moduleIdentity.version.map { it.version }' '    parameters.gradleVersion.set(moduleIdentity.version.map { it.version })' \
      --replace-fail '    parameters.homeDir = intTestHomeDir' '    parameters.homeDir.set(intTestHomeDir)' \
      --replace-fail '    cachesCleaner = cachesCleanerService' '    cachesCleaner.set(cachesCleanerService)' \
      --replace-fail '        tracker = it.service' '        tracker.set(it.service)' \
      --replace-fail '        gradleUserHomeDir = intTestHomeDir' '        gradleUserHomeDir.set(intTestHomeDir)' \
      --replace-fail '        daemonRegistry = repoRoot().dir("build/daemon")' '        daemonRegistry.set(repoRoot().dir("build/daemon"))' \
      --replace-fail '        gradleSnippetsDir = repoRoot().dir("$docsProjectLocation/src/snippets")' '        gradleSnippetsDir.set(repoRoot().dir("$docsProjectLocation/src/snippets"))'
    substituteInPlace build-logic/integration-testing/src/main/kotlin/gradlebuild/integrationtests/shared-configuration.kt \
      --replace-fail '    parameters.includeTestClasses = project.testSplitIncludeTestClasses' '    parameters.includeTestClasses.set(project.testSplitIncludeTestClasses)' \
      --replace-fail '    parameters.excludeTestClasses = project.testSplitExcludeTestClasses' '    parameters.excludeTestClasses.set(project.testSplitExcludeTestClasses)' \
      --replace-fail '    parameters.onlyTestGradleVersion = project.testSplitOnlyTestGradleVersion' '    parameters.onlyTestGradleVersion.set(project.testSplitOnlyTestGradleVersion)' \
      --replace-fail '    parameters.repoRoot = repoRoot()' '    parameters.repoRoot.set(repoRoot())'
    substituteInPlace build-logic/integration-testing/src/main/kotlin/gradlebuild/integrationtests/tasks/GenerateLanguageAnnotations.kt \
      --replace-fail '            packageName = this@GenerateLanguageAnnotations.packageName' '            packageName.set(this@GenerateLanguageAnnotations.packageName)' \
      --replace-fail '            destDir = this@GenerateLanguageAnnotations.destDir' '            destDir.set(this@GenerateLanguageAnnotations.destDir)'
    substituteInPlace build-logic/root-build/src/main/kotlin/gradlebuild.build-environment.gradle.kts \
      --replace-fail 'buildEnvironmentExtension.gitCommitId = git("rev-parse", "HEAD")' 'buildEnvironmentExtension.gitCommitId.set(git("rev-parse", "HEAD"))' \
      --replace-fail 'buildEnvironmentExtension.gitBranch = git("rev-parse", "--abbrev-ref", "HEAD")' 'buildEnvironmentExtension.gitBranch.set(git("rev-parse", "--abbrev-ref", "HEAD"))' \
      --replace-fail 'buildEnvironmentExtension.repoRoot = layout.projectDirectory.parentOrRoot()' 'buildEnvironmentExtension.repoRoot.set(layout.projectDirectory.parentOrRoot())'
    substituteInPlace build-logic/performance-testing/src/main/kotlin/gradlebuild/performance/PerformanceTestPlugin.kt \
      --replace-fail '        performanceTestExtension.baselines = project.performanceBaselines' '        performanceTestExtension.baselines.set(project.performanceBaselines)' \
      --replace-fail '            performanceResultsDirectory = repoRoot().dir("perf-results")' '            performanceResultsDirectory.set(repoRoot().dir("perf-results"))' \
      --replace-fail '            reportDir = project.layout.buildDirectory.dir(this@configureEach.name)' '            reportDir.set(project.layout.buildDirectory.dir(this@configureEach.name))' \
      --replace-fail '            databaseParameters = project.propertiesForPerformanceDb' '            databaseParameters.set(project.propertiesForPerformanceDb)' \
      --replace-fail '            branchName = buildBranch' '            branchName.set(buildBranch)' \
      --replace-fail '            commitId = buildCommitId' '            commitId.set(buildCommitId)' \
      --replace-fail '            projectName = project.name' '            projectName.set(project.name)' \
      --replace-fail '            mainClass = "org.gradle.performance.results.PerformanceTestRuntimesGenerator"' '            mainClass.set("org.gradle.performance.results.PerformanceTestRuntimesGenerator")' \
      --replace-fail '            mainClass = "org.gradle.performance.fixture.PerformanceTestScenarioDefinitionVerifier"' '            mainClass.set("org.gradle.performance.fixture.PerformanceTestScenarioDefinitionVerifier")' \
      --replace-fail '            predictiveSelection.enabled = false' '            predictiveSelection.enabled.set(false)' \
      --replace-fail '            this.reportGeneratorClass = reportGeneratorClass' '            this.reportGeneratorClass.set(reportGeneratorClass)' \
      --replace-fail '            this.dependencyBuildIds = project.performanceDependencyBuildIds' '            this.dependencyBuildIds.set(project.performanceDependencyBuildIds)' \
      --replace-fail '            maxParallelUsages = 1' '            maxParallelUsages.set(1)' \
      --replace-fail '            configuredBaselines = extension.baselines' '            configuredBaselines.set(extension.baselines)' \
      --replace-fail '            defaultBaselines = project.defaultPerformanceBaselines' '            defaultBaselines.set(project.defaultPerformanceBaselines)' \
      --replace-fail '            logicalBranch = project.logicalBranch' '            logicalBranch.set(project.logicalBranch)' \
      --replace-fail '            releasedVersionsFile = project.releasedVersionsFile()' '            releasedVersionsFile.set(project.releasedVersionsFile())' \
      --replace-fail '            commitBaseline = determineBaselines.flatMap { it.determinedBaselines }' '            commitBaseline.set(determineBaselines.flatMap { it.determinedBaselines })' \
      --replace-fail '            commitDistribution = buildCommitDistributionsDir.zip(commitBaseline) { dir, version -> dir.file("gradle-$version.zip") }' '            commitDistribution.set(buildCommitDistributionsDir.zip(commitBaseline) { dir, version -> dir.file("gradle-$version.zip") })' \
      --replace-fail '            commitDistributionToolingApiJar = buildCommitDistributionsDir.zip(commitBaseline) { dir, version -> dir.file("gradle-$version-tooling-api.jar") }' '            commitDistributionToolingApiJar.set(buildCommitDistributionsDir.zip(commitBaseline) { dir, version -> dir.file("gradle-$version-tooling-api.jar") })' \
      --replace-fail '            commitDistributionsDir = buildCommitDistributionsDir' '            commitDistributionsDir.set(buildCommitDistributionsDir)' \
      --replace-fail '            baselines = determineBaselines.flatMap { it.determinedBaselines }' '            baselines.set(determineBaselines.flatMap { it.determinedBaselines })' \
      --replace-fail '        destinationDirectory = buildDir' '        destinationDirectory.set(buildDir)' \
      --replace-fail '        archiveFileName = "performance-test-results.zip"' '        archiveFileName.set("performance-test-results.zip")' \
      --replace-fail '                extensions.findByType<TestRetryExtension>()?.maxRetries = 0' '                extensions.findByType<TestRetryExtension>()?.maxRetries?.set(0)' \
      --replace-fail '                extensions.findByType<TestRetryExtension>()?.maxRetries = 1' '                extensions.findByType<TestRetryExtension>()?.maxRetries?.set(1)' \
      --replace-fail '            performanceTestService = buildService' '            performanceTestService.set(buildService)' \
      --replace-fail '            testProjectName = generatorTask.name' '            testProjectName.set(generatorTask.name)' \
      --replace-fail '            commitId = project.buildCommitId' '            commitId.set(project.buildCommitId)' \
      --replace-fail '            reportGeneratorClass = "org.gradle.performance.results.report.DefaultReportGenerator"' '            reportGeneratorClass.set("org.gradle.performance.results.report.DefaultReportGenerator")' \
      --replace-fail '            destinationDirectory = project.layout.buildDirectory' '            destinationDirectory.set(project.layout.buildDirectory)' \
      --replace-fail '            archiveFileName = "test-results-''${junitXmlDir.name}.zip"' '            archiveFileName.set("test-results-''${junitXmlDir.name}.zip")'
    substituteInPlace build-logic/performance-testing/src/main/kotlin/gradlebuild/performance/tasks/DetermineBaselines.kt \
      --replace-fail '            determinedBaselines = determineFlakinessDetectionBaseline()' '            determinedBaselines.set(determineFlakinessDetectionBaseline())' \
      --replace-fail '            determinedBaselines = configuredBaselines' '            determinedBaselines.set(configuredBaselines)' \
      --replace-fail '            determinedBaselines = defaultBaselines' '            determinedBaselines.set(defaultBaselines)' \
      --replace-fail '            determinedBaselines = forkPointCommitBaseline()' '            determinedBaselines.set(forkPointCommitBaseline())'
    substituteInPlace build-logic/buildquality/src/main/kotlin/gradlebuild.arch-test.gradle.kts \
      --replace-fail '                            enabled = false' '                            enabled.set(false)'
    substituteInPlace build-logic/buildquality/src/main/kotlin/gradlebuild.configure-ci-artifacts.gradle.kts \
      --replace-fail '        globalExtension.taskPathToReports = taskPathToReports' '        globalExtension.taskPathToReports.set(taskPathToReports)'
    substituteInPlace build-logic/buildquality/src/main/kotlin/gradlebuild.incubation-report-aggregation.gradle.kts \
      --replace-fail '    htmlReportFile = project.layout.buildDirectory.file("reports/incubation/all-incubating.html")' '    htmlReportFile.set(project.layout.buildDirectory.file("reports/incubation/all-incubating.html"))' \
      --replace-fail '    destinationDirectory = layout.buildDirectory.dir("reports/incubation")' '    destinationDirectory.set(layout.buildDirectory.dir("reports/incubation"))' \
      --replace-fail '    archiveBaseName = "incubating-apis"' '    archiveBaseName.set("incubating-apis")'
    substituteInPlace build-logic/buildquality/src/main/kotlin/gradlebuild.incubation-report.gradle.kts \
      --replace-fail '    title = project.name' '    title.set(project.name)' \
      --replace-fail '    versionFile = repoRoot().file("version.txt")' '    versionFile.set(repoRoot().file("version.txt"))' \
      --replace-fail '    releasedVersionsFile = releasedVersionsFile()' '    releasedVersionsFile.set(releasedVersionsFile())' \
      --replace-fail '    htmlReportFile = file(layout.buildDirectory.file("reports/incubation/''${project.name}.html"))' '    htmlReportFile.set(file(layout.buildDirectory.file("reports/incubation/''${project.name}.html")))' \
      --replace-fail '    textReportFile = file(layout.buildDirectory.file("reports/incubation/''${project.name}.txt"))' '    textReportFile.set(file(layout.buildDirectory.file("reports/incubation/''${project.name}.txt")))'
    substituteInPlace build-logic/buildquality/src/main/kotlin/gradlebuild.task-properties-validation.gradle.kts \
      --replace-fail '    outputFile = project.reporting.baseDirectory.file(reportFileName)' '    outputFile.set(project.reporting.baseDirectory.file(reportFileName))' \
      --replace-fail '    enableStricterValidation = true' '    enableStricterValidation.set(true)'
    substituteInPlace build-logic/buildquality/src/main/kotlin/gradlebuild/incubation/tasks/IncubatingApiAggregateReportTask.kt \
      --replace-fail '        htmlReportFile = this@IncubatingApiAggregateReportTask.htmlReportFile' '        htmlReportFile.set(this@IncubatingApiAggregateReportTask.htmlReportFile)'
    substituteInPlace build-logic/buildquality/src/main/kotlin/gradlebuild/incubation/tasks/IncubatingApiReportTask.kt \
      --replace-fail '        htmlReportFile = this@IncubatingApiReportTask.htmlReportFile' '        htmlReportFile.set(this@IncubatingApiReportTask.htmlReportFile)' \
      --replace-fail '        textReportFile = this@IncubatingApiReportTask.textReportFile' '        textReportFile.set(this@IncubatingApiReportTask.textReportFile)' \
      --replace-fail '        title = this@IncubatingApiReportTask.title' '        title.set(this@IncubatingApiReportTask.title)' \
      --replace-fail '        releasedVersionsFile = this@IncubatingApiReportTask.releasedVersionsFile' '        releasedVersionsFile.set(this@IncubatingApiReportTask.releasedVersionsFile)'
    substituteInPlace build-logic/buildquality/src/main/kotlin/gradlebuild/quickcheck/tasks/QuickCheckTask.kt \
      --replace-fail '                mainClass = "com.puppycrawl.tools.checkstyle.Main"' '                mainClass.set("com.puppycrawl.tools.checkstyle.Main")' \
      --replace-fail '                    mainClass = "org.codenarc.CodeNarc"' '                    mainClass.set("org.codenarc.CodeNarc")' \
      --replace-fail '                mainClass = "com.pinterest.ktlint.Main"' '                mainClass.set("com.pinterest.ktlint.Main")'
    substituteInPlace build-logic/publishing/src/main/kotlin/gradlebuild.kotlin-dsl-plugin-bundle.gradle.kts \
      --replace-fail '    enableStricterValidation = true' '    enableStricterValidation.set(true)' \
      --replace-fail '                name = "The Apache License, Version 2.0"' '                name.set("The Apache License, Version 2.0")' \
      --replace-fail '                url = "http://www.apache.org/licenses/LICENSE-2.0.txt"' '                url.set("http://www.apache.org/licenses/LICENSE-2.0.txt")' \
      --replace-fail '    destinationFile = futurePluginVersionsPropertiesFile' '    outputFile = futurePluginVersionsPropertiesFile.get().asFile' \
      --replace-fail '    website = "https://github.com/gradle/gradle/tree/HEAD/subprojects/kotlin-dsl-plugins"' '    website.set("https://github.com/gradle/gradle/tree/HEAD/subprojects/kotlin-dsl-plugins")' \
      --replace-fail '    vcsUrl = "https://github.com/gradle/gradle/tree/HEAD/subprojects/kotlin-dsl-plugins"' '    vcsUrl.set("https://github.com/gradle/gradle/tree/HEAD/subprojects/kotlin-dsl-plugins")'
    substituteInPlace build-logic/publishing/src/main/kotlin/gradlebuild.publish-public-libraries.gradle.kts \
      --replace-fail '        name = "org.gradle:gradle-''${project.name}"' '        name.set("org.gradle:gradle-''${project.name}")' \
      --replace-fail $'        description = provider {\n            require(project.description != null) { "You must set the description of published project ''${project.name}" }\n            project.description\n        }' $'        description.set(provider {\n            require(project.description != null) { "You must set the description of published project ''${project.name}" }\n            project.description\n        })' \
      --replace-fail '        url = "https://gradle.org"' '        url.set("https://gradle.org")' \
      --replace-fail '                name = "Apache-2.0"' '                name.set("Apache-2.0")' \
      --replace-fail '                url = "http://www.apache.org/licenses/LICENSE-2.0.txt"' '                url.set("http://www.apache.org/licenses/LICENSE-2.0.txt")' \
      --replace-fail '                name = "The Gradle team"' '                name.set("The Gradle team")' \
      --replace-fail '                organization = "Gradle Inc."' '                organization.set("Gradle Inc.")' \
      --replace-fail '                organizationUrl = "https://gradle.org"' '                organizationUrl.set("https://gradle.org")' \
      --replace-fail '            connection = "scm:git:git://github.com/gradle/gradle.git"' '            connection.set("scm:git:git://github.com/gradle/gradle.git")' \
      --replace-fail '            developerConnection = "scm:git:ssh://github.com:gradle/gradle.git"' '            developerConnection.set("scm:git:ssh://github.com:gradle/gradle.git")' \
      --replace-fail '            url = "https://github.com/gradle/gradle"' '            url.set("https://github.com/gradle/gradle")'
    substituteInPlace build-logic/jvm/src/main/kotlin/gradlebuild.api-parameter-names-index.gradle.kts \
      --replace-fail $'    destinationFile = project.layout.buildDirectory.file(\n        moduleIdentity.baseName.map { "generated-resources/$it-parameter-names/$it-parameter-names.properties" }\n    )' $'    destinationFile.set(project.layout.buildDirectory.file(\n        moduleIdentity.baseName.map { "generated-resources/$it-parameter-names/$it-parameter-names.properties" }\n    ))'
    substituteInPlace build-logic/jvm/src/main/kotlin/gradlebuild.launchable-jar.gradle.kts \
      --replace-fail '    startScriptsDir = layout.buildDirectory.dir("startScripts")' '    startScriptsDir.set(layout.buildDirectory.dir("startScripts"))'
    substituteInPlace build-logic/jvm/src/main/kotlin/gradlebuild.unittest-and-compile.gradle.kts \
      --replace-fail '    options.release = 8' '    options.release.set(8)' \
      --replace-fail '        this.manifestFile = moduleIdentity.baseName.map { layout.buildDirectory.file("generated-resources/$it-classpath/$it-classpath.properties").get() }' '        this.manifestFile.set(moduleIdentity.baseName.map { layout.buildDirectory.file("generated-resources/$it-classpath/$it-classpath.properties").get() })' \
      --replace-fail '        archiveBaseName = moduleIdentity.baseName' '        archiveBaseName.set(moduleIdentity.baseName)' \
      --replace-fail '        archiveVersion = moduleIdentity.version.map { it.baseVersion.version }' '        archiveVersion.set(moduleIdentity.version.map { it.baseVersion.version })' \
      --replace-fail '        languageVersion = jvmVersionForTest()' '        languageVersion.set(jvmVersionForTest())' \
      --replace-fail '        vendor = project.testJavaVendor.orNull' '        vendor.set(project.testJavaVendor.orNull)' \
      --replace-fail '    javaLauncher = launcher' '    javaLauncher.set(launcher)' \
      --replace-fail '                maxFailures = determineMaxFailures()' '                maxFailures.set(determineMaxFailures())' \
      --replace-fail 'server = uri("https://ge-td-dogfooding.grdev.net")' 'server.set(uri("https://ge-td-dogfooding.grdev.net"))' \
      --replace-fail '                enabled = true' '                enabled.set(true)' \
      --replace-fail '                    preferredMaxDuration = Duration.ofSeconds(this)' '                    preferredMaxDuration.set(Duration.ofSeconds(this))' \
      --replace-fail '                distribution.maxRemoteExecutors = if (project.isPerformanceProject()) 0 else null' '                distribution.maxRemoteExecutors.set(if (project.isPerformanceProject()) 0 else null)' \
      --replace-fail '                        OperatingSystem.current().isLinux -> requirements = listOf("os=linux", "gbt-dogfooding")' '                        OperatingSystem.current().isLinux -> requirements.set(listOf("os=linux", "gbt-dogfooding"))' \
      --replace-fail '                        OperatingSystem.current().isWindows -> requirements = listOf("os=windows", "gbt-dogfooding")' '                        OperatingSystem.current().isWindows -> requirements.set(listOf("os=windows", "gbt-dogfooding"))' \
      --replace-fail '                        OperatingSystem.current().isMacOsX -> requirements = listOf("os=macos", "gbt-dogfooding")' '                        OperatingSystem.current().isMacOsX -> requirements.set(listOf("os=macos", "gbt-dogfooding"))' \
      --replace-fail '                    requirements = listOf("gbt-dogfooding")' '                    requirements.set(listOf("gbt-dogfooding"))' \
      --replace-fail 'server = uri("https://ge.gradle.org")' 'server.set(uri("https://ge.gradle.org"))'
    substituteInPlace build-logic/jvm/src/main/kotlin/gradlebuild/jvm/extension/UnitTestAndCompileExtension.kt \
      --replace-fail '            options.release = null' '            options.release.set(null as Int?)'
    substituteInPlace build-logic/uber-plugins/src/main/kotlin/gradlebuild.kotlin-library.gradle.kts \
      --replace-fail '        allWarningsAsErrors = true' '        allWarningsAsErrors.set(true)' \
      --replace-fail '        apiVersion = KotlinVersion.KOTLIN_1_8' '        apiVersion.set(KotlinVersion.KOTLIN_1_8)' \
      --replace-fail '        languageVersion = KotlinVersion.KOTLIN_1_8' '        languageVersion.set(KotlinVersion.KOTLIN_1_8)' \
      --replace-fail '        jvmTarget = JvmTarget.JVM_1_8' '        jvmTarget.set(JvmTarget.JVM_1_8)'
    substituteInPlace build-logic/packaging/src/main/kotlin/gradlebuild.api-metadata.gradle.kts \
      --replace-fail '    destinationFile = apiDeclarationPropertiesFile' '    outputFile = apiDeclarationPropertiesFile.get().asFile'
    substituteInPlace build-logic/packaging/src/main/kotlin/gradlebuild.distributions.gradle.kts \
      --replace-fail '    outputFile = generatedTxtFileFor("api-relocated")' '    outputFile.set(generatedTxtFileFor("api-relocated"))' \
      --replace-fail '    destinationFile = generatedBinFileFor("dsl-meta-data.bin")' '    destinationFile.set(generatedBinFileFor("dsl-meta-data.bin"))' \
      --replace-fail '    metaDataFile = dslMetaData.flatMap(ExtractDslMetaDataTask::getDestinationFile)' '    metaDataFile.set(dslMetaData.flatMap(ExtractDslMetaDataTask::getDestinationFile))' \
      --replace-fail '    importsDestFile = generatedTxtFileFor("default-imports")' '    importsDestFile.set(generatedTxtFileFor("default-imports"))' \
      --replace-fail '    excludedPackages = GradleUserManualPlugin.getDefaultExcludedPackages()' '    excludedPackages.set(GradleUserManualPlugin.getDefaultExcludedPackages())' \
      --replace-fail '    mappingDestFile = generatedTxtFileFor("api-mapping")' '    mappingDestFile.set(generatedTxtFileFor("api-mapping"))' \
      --replace-fail '    this.manifestFile = generatedPropertiesFileFor("$runtimeApiJarName-classpath")' '    this.manifestFile.set(generatedPropertiesFileFor("$runtimeApiJarName-classpath"))' \
      --replace-fail '    archiveVersion = moduleIdentity.version.map { it.baseVersion.version }' '    archiveVersion.set(moduleIdentity.version.map { it.baseVersion.version })' \
      --replace-fail '    archiveBaseName = runtimeApiJarName' '    archiveBaseName.set(runtimeApiJarName)' \
      --replace-fail '        manifestFile = generatedPropertiesFileFor("gradle''${if (api == GradleModuleApiAttribute.API) "" else "-implementation"}-plugins")' '        manifestFile.set(generatedPropertiesFileFor("gradle''${if (api == GradleModuleApiAttribute.API) "" else "-implementation"}-plugins"))' \
      --replace-fail '        archiveBaseName = "gradle"' '        archiveBaseName.set("gradle")' \
      --replace-fail '        archiveClassifier = name' '        archiveClassifier.set(name)' \
      --replace-fail '        destinationDirectory = project.layout.buildDirectory.dir(disDir)' '        destinationDirectory.set(project.layout.buildDirectory.dir(disDir))'
    substituteInPlace build-logic/packaging/src/main/kotlin/gradlebuild.shaded-jar.gradle.kts \
      --replace-fail '                shadowPackage = "org.gradle.internal.impldep"' '                shadowPackage.set("org.gradle.internal.impldep")' \
      --replace-fail '                keepPackages = shadedJarExtension.keepPackages' '                keepPackages.set(shadedJarExtension.keepPackages)' \
      --replace-fail '                unshadedPackages = shadedJarExtension.unshadedPackages' '                unshadedPackages.set(shadedJarExtension.unshadedPackages)' \
      --replace-fail '                ignoredPackages = shadedJarExtension.ignoredPackages' '                ignoredPackages.set(shadedJarExtension.ignoredPackages)' \
      --replace-fail '        jarFile = layout.buildDirectory.file(provider { "shaded-jar/''${moduleIdentity.baseName.get()}-shaded-''${moduleIdentity.version.get().baseVersion.version}.jar" })' '        jarFile.set(layout.buildDirectory.file(provider { "shaded-jar/''${moduleIdentity.baseName.get()}-shaded-''${moduleIdentity.version.get().baseVersion.version}.jar" }))' \
      --replace-fail '            name = moduleIdentity.baseName.get()' '            name = moduleIdentity.baseName.get()' \
      --replace-fail '            type = "jar"' '            type = "jar"'
    substituteInPlace build-logic/packaging/src/main/kotlin/gradlebuild/run/tasks/RunEmbeddedGradle.kt \
      --replace-fail '            mainClass = "org.gradle.launcher.Main"' '            mainClass.set("org.gradle.launcher.Main")'
    substituteInPlace subprojects/architecture-test/build.gradle.kts \
      --replace-fail '    apiChangesFile = acceptedApiChangesFile' '    apiChangesFile.set(acceptedApiChangesFile)' \
      --replace-fail '        enabled = false' '        enabled.set(false)'
    substituteInPlace subprojects/base-services/build.gradle.kts \
      --replace-fail '    options.release = 8' '    options.release.set(8)' \
      --replace-fail 'jmh.includes = listOf("HashingAlgorithmsBenchmark")' 'jmh.includes.set(listOf("HashingAlgorithmsBenchmark"))'
    substituteInPlace subprojects/build-scan-performance/build.gradle.kts \
      --replace-fail '    reportGeneratorClass = "org.gradle.performance.results.BuildScanReportGenerator"' '    reportGeneratorClass.set("org.gradle.performance.results.BuildScanReportGenerator")'
    substituteInPlace subprojects/composite-builds/build.gradle.kts \
      --replace-fail 'testFilesCleanup.reportOnly = true' 'testFilesCleanup.reportOnly.set(true)'
    substituteInPlace build-logic/kotlin-dsl/src/main/kotlin/gradlebuild.kotlin-dsl-dependencies-embedded.gradle.kts \
      --replace-fail '        outputDir = apiExtensionsOutputDir' '        outputDir.set(apiExtensionsOutputDir)' \
      --replace-fail '        embeddedKotlinVersion = libs.kotlinVersion' '        embeddedKotlinVersion.set(libs.kotlinVersion)' \
      --replace-fail '        kotlinDslPluginsVersion = publishedKotlinDslPluginVersion' '        kotlinDslPluginsVersion.set(publishedKotlinDslPluginVersion)' \
      --replace-fail '        destinationFile = layout.buildDirectory.file("versionsManifest/gradle-kotlin-dsl-versions.properties")' '        outputFile = layout.buildDirectory.file("versionsManifest/gradle-kotlin-dsl-versions.properties").get().asFile'
    substituteInPlace build-logic/kotlin-dsl/src/main/kotlin/gradlebuild.kotlin-dsl-plugin-extensions.gradle.kts \
      --replace-fail '    outputDir = generatedSourcesDir' '    outputDir.set(generatedSourcesDir)' \
      --replace-fail '    kotlinDslPluginsVersion = project.version' '    kotlinDslPluginsVersion.set(project.version)'
    substituteInPlace subprojects/core/build.gradle.kts \
      --replace-fail 'integTest.usesJavadocCodeSnippets = true' 'integTest.usesJavadocCodeSnippets.set(true)' \
      --replace-fail 'testFilesCleanup.reportOnly = true' 'testFilesCleanup.reportOnly.set(true)'
    substituteInPlace subprojects/core-api/build.gradle.kts \
      --replace-fail 'integTest.usesJavadocCodeSnippets = true' 'integTest.usesJavadocCodeSnippets.set(true)' \
      --replace-fail 'testFilesCleanup.reportOnly = true' 'testFilesCleanup.reportOnly.set(true)'
    substituteInPlace subprojects/dependency-management/build.gradle.kts \
      --replace-fail 'testFilesCleanup.reportOnly = true' 'testFilesCleanup.reportOnly.set(true)'
    substituteInPlace subprojects/ide/build.gradle.kts \
      --replace-fail 'integTest.usesJavadocCodeSnippets = true' 'integTest.usesJavadocCodeSnippets.set(true)' \
      --replace-fail 'testFilesCleanup.reportOnly = true' 'testFilesCleanup.reportOnly.set(true)'
    substituteInPlace subprojects/ide-native/build.gradle.kts \
      --replace-fail 'integTest.usesJavadocCodeSnippets = true' 'integTest.usesJavadocCodeSnippets.set(true)'
    substituteInPlace subprojects/integ-test/build.gradle.kts \
      --replace-fail 'testFilesCleanup.reportOnly = true' 'testFilesCleanup.reportOnly.set(true)'
    substituteInPlace subprojects/ivy/build.gradle.kts \
      --replace-fail 'integTest.usesJavadocCodeSnippets = true' 'integTest.usesJavadocCodeSnippets.set(true)'
    substituteInPlace subprojects/java-compiler-plugin/build.gradle.kts \
      --replace-fail '    options.release = null' '    options.release.set(null as Int?)'
    substituteInPlace subprojects/kotlin-dsl/build.gradle.kts \
      --replace-fail 'testFilesCleanup.reportOnly = true' 'testFilesCleanup.reportOnly.set(true)'
    substituteInPlace subprojects/kotlin-dsl-integ-tests/build.gradle.kts \
      --replace-fail 'testFilesCleanup.reportOnly = true' 'testFilesCleanup.reportOnly.set(true)'
    substituteInPlace subprojects/kotlin-dsl-plugins/build.gradle.kts \
      --replace-fail 'base.archivesName = "plugins"' 'base.archivesName.set("plugins")' \
      --replace-fail 'testFilesCleanup.reportOnly = true' 'testFilesCleanup.reportOnly.set(true)'
    substituteInPlace subprojects/kotlin-dsl-tooling-builders/build.gradle.kts \
      --replace-fail 'testFilesCleanup.reportOnly = true' 'testFilesCleanup.reportOnly.set(true)'
    substituteInPlace subprojects/language-java/build.gradle.kts \
      --replace-fail '    options.release = null' '    options.release.set(null as Int?)' \
      --replace-fail 'integTest.usesJavadocCodeSnippets = true' 'integTest.usesJavadocCodeSnippets.set(true)'
    substituteInPlace subprojects/language-native/build.gradle.kts \
      --replace-fail 'integTest.usesJavadocCodeSnippets = true' 'integTest.usesJavadocCodeSnippets.set(true)'
    substituteInPlace subprojects/launcher/build.gradle.kts \
      --replace-fail 'testFilesCleanup.reportOnly = true' 'testFilesCleanup.reportOnly.set(true)'
    substituteInPlace subprojects/maven/build.gradle.kts \
      --replace-fail 'integTest.usesJavadocCodeSnippets = true' 'integTest.usesJavadocCodeSnippets.set(true)'
    substituteInPlace subprojects/model-core/build.gradle.kts \
      --replace-fail '    options.release = null' '    options.release.set(null as Int?)' \
      --replace-fail 'integTest.usesJavadocCodeSnippets = true' 'integTest.usesJavadocCodeSnippets.set(true)'
    substituteInPlace subprojects/native/build.gradle.kts \
      --replace-fail '    options.release = 8' '    options.release.set(8)' \
      --replace-fail '    fork = 1' '    fork.set(1)' \
      --replace-fail '    threads = 2' '    threads.set(2)' \
      --replace-fail '    warmupIterations = 10' '    warmupIterations.set(10)' \
      --replace-fail '    synchronizeIterations = false' '    synchronizeIterations.set(false)'
    substituteInPlace subprojects/platform-base/build.gradle.kts \
      --replace-fail 'integTest.usesJavadocCodeSnippets = true' 'integTest.usesJavadocCodeSnippets.set(true)'
    substituteInPlace subprojects/platform-jvm/build.gradle.kts \
      --replace-fail 'integTest.usesJavadocCodeSnippets = true' 'integTest.usesJavadocCodeSnippets.set(true)'
    substituteInPlace subprojects/platform-native/build.gradle.kts \
      --replace-fail 'integTest.usesJavadocCodeSnippets = true' 'integTest.usesJavadocCodeSnippets.set(true)'
    substituteInPlace subprojects/plugin-development/build.gradle.kts \
      --replace-fail 'integTest.usesJavadocCodeSnippets = true' 'integTest.usesJavadocCodeSnippets.set(true)'
    substituteInPlace subprojects/plugin-use/build.gradle.kts \
      --replace-fail 'testFilesCleanup.reportOnly = true' 'testFilesCleanup.reportOnly.set(true)'
    substituteInPlace subprojects/plugins/build.gradle.kts \
      --replace-fail 'integTest.usesJavadocCodeSnippets = true' 'integTest.usesJavadocCodeSnippets.set(true)' \
      --replace-fail 'testFilesCleanup.reportOnly = true' 'testFilesCleanup.reportOnly.set(true)'
    substituteInPlace subprojects/publish/build.gradle.kts \
      --replace-fail 'integTest.usesJavadocCodeSnippets = true' 'integTest.usesJavadocCodeSnippets.set(true)'
    substituteInPlace subprojects/samples/build.gradle.kts \
      --replace-fail 'testFilesCleanup.reportOnly = true' 'testFilesCleanup.reportOnly.set(true)'
    substituteInPlace subprojects/scala/build.gradle.kts \
      --replace-fail 'integTest.usesJavadocCodeSnippets = true' 'integTest.usesJavadocCodeSnippets.set(true)'
    substituteInPlace subprojects/signing/build.gradle.kts \
      --replace-fail 'integTest.usesJavadocCodeSnippets = true' 'integTest.usesJavadocCodeSnippets.set(true)'
    substituteInPlace subprojects/smoke-test/build.gradle.kts \
      --replace-fail '        remoteUri = santaGitUri' '        remoteUri.set(santaGitUri)' \
      --replace-fail '        ref = "180b7a91054d5fe5b617543bb2f74a3819537b7b"' '        ref.set("180b7a91054d5fe5b617543bb2f74a3819537b7b")' \
      --replace-fail '        remoteUri = rootDir.absolutePath' '        remoteUri.set(rootDir.absolutePath)' \
      --replace-fail '        ref = buildCommitId' '        ref.set(buildCommitId)'
    substituteInPlace subprojects/testing-base/build.gradle.kts \
      --replace-fail 'integTest.usesJavadocCodeSnippets = true' 'integTest.usesJavadocCodeSnippets.set(true)'
    substituteInPlace subprojects/testing-jvm/build.gradle.kts \
      --replace-fail 'integTest.usesJavadocCodeSnippets = true' 'integTest.usesJavadocCodeSnippets.set(true)'
    substituteInPlace subprojects/test-kit/build.gradle.kts \
      --replace-fail '    outputFile = layout.buildDirectory.file("runtime-api-info/test-kit-relocated.txt")' '    outputFile.set(layout.buildDirectory.file("runtime-api-info/test-kit-relocated.txt"))'
    substituteInPlace subprojects/tooling-api/build.gradle.kts \
      --replace-fail '    keepPackages = listOf("org.gradle.tooling")' '    keepPackages.set(listOf("org.gradle.tooling"))' \
      --replace-fail '    unshadedPackages = listOf("org.gradle", "org.slf4j", "sun.misc")' '    unshadedPackages.set(listOf("org.gradle", "org.slf4j", "sun.misc"))' \
      --replace-fail '    ignoredPackages = setOf("org.gradle.tooling.provider.model")' '    ignoredPackages.set(setOf("org.gradle.tooling.provider.model"))' \
      --replace-fail 'integTest.usesJavadocCodeSnippets = true' 'integTest.usesJavadocCodeSnippets.set(true)' \
      --replace-fail 'testFilesCleanup.reportOnly = true' 'testFilesCleanup.reportOnly.set(true)'
    substituteInPlace subprojects/wrapper/build.gradle.kts \
      --replace-fail '    archiveFileName = "gradle-wrapper.jar"' '    archiveFileName.set("gradle-wrapper.jar")'
    substituteInPlace build-logic/build-init-samples/src/main/kotlin/gradlebuild/generate-samples.gradle.kts \
      --replace-fail '        type = buildInitType' '        type.set(buildInitType)' \
      --replace-fail '        modularization = modularizationOption' '        modularization.set(modularizationOption)' \
      --replace-fail '        dsls = setOf(Dsl.GROOVY, Dsl.KOTLIN)' '        dsls.set(setOf(Dsl.GROOVY, Dsl.KOTLIN))' \
      --replace-fail '        sampleDirectory = generateSampleTask.flatMap { it.target }' '        sampleDirectory.set(generateSampleTask.flatMap { it.target })' \
      --replace-fail '        displayName = "Building $languageDisplayName $capKind$multiProjectSuffix"' '        displayName.set("Building $languageDisplayName $capKind$multiProjectSuffix")' \
      --replace-fail '        description = "Setup a $languageDisplayName $kind project$multiProjectSuffix step-by-step."' '        description.set("Setup a $languageDisplayName $kind project$multiProjectSuffix step-by-step.")' \
      --replace-fail '        category = language.toString()' '        category.set(language.toString())'
  '';
}
