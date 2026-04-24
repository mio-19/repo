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
  version = "8.1";
  hash = "sha256-+IBfbf43KyIxOhkJbuI8r3TughQrSzCdz6PcGIsF6Zg=";
  lockFile = mergeLock [
    gradle_8_1_20230203.unwrapped.passthru.lockFile
    ./more.gradle.lock
  ];
  defaultJava = jdk21_headless;
  # this version specifically ask for termurin branded jdk.
  buildJdk = temurin-bin-11;
  javaToolchains = [
    temurin-bin-8
    temurin-bin-11
    temurin-bin-17
  ];
  bootstrapGradle = gradle_8_1_20230203;
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
  '';
}
