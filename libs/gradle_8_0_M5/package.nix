{
  temurin-bin-8,
  temurin-bin-11,
  temurin-bin-17,
  jdk21_headless,
  gradle_8_0_M4,
  gradle_8_0_20220911,
  gradle-from-source,
  mergeLock,
}:
gradle-from-source {
  version = "8.0.0-M5";
  tag = "v8.0.0-M5";
  hash = "sha256-FH8WGg/9J1VejkFwWYUoCnYya/dpLpCHNtyxNOiSi7A=";
  lockFile = mergeLock [
    gradle_8_0_M4.unwrapped.passthru.lockFile
    gradle_8_0_20220911.unwrapped.passthru.lockFile
    ../gradle_8_0/more.gradle.lock
    ../gradle_7_6_rc1/more.gradle.lock
    ../gradle_7_6_rc4/more.gradle.lock
  ];
  defaultJava = jdk21_headless;
  # this version specifically ask for termurin branded jdk.
  buildJdk = temurin-bin-11;
  javaToolchains = [
    temurin-bin-8
    temurin-bin-11
    temurin-bin-17
  ];
  bootstrapGradle = gradle_8_0_M4;
  postPatch = ''
    substituteInPlace build-logic-commons/gradle-plugin/build.gradle.kts \
      --replace-fail 'implementation("org.gradle.kotlin.kotlin-dsl:org.gradle.kotlin.kotlin-dsl.gradle.plugin:3.2.6")' 'implementation("org.gradle.kotlin.kotlin-dsl:org.gradle.kotlin.kotlin-dsl.gradle.plugin:4.0.6")' \
      --replace-fail 'implementation("org.jetbrains.kotlin:kotlin-gradle-plugin:1.7.22")' 'implementation("org.jetbrains.kotlin:kotlin-gradle-plugin:1.8.10")'
    substituteInPlace build-logic/kotlin-dsl/src/main/kotlin/gradlebuild.kotlin-dsl-dependencies-embedded.gradle.kts \
      --replace-fail 'val publishedKotlinDslPluginVersion = "3.2.6" // TODO:kotlin-dsl' 'val publishedKotlinDslPluginVersion = "4.0.6" // TODO:kotlin-dsl'
    substituteInPlace build-logic/dependency-modules/src/main/kotlin/gradlebuild/modules/extension/ExternalModulesExtension.kt \
      --replace-fail '    val kotlinVersion = "1.7.22"' '    val kotlinVersion = "1.8.10"'
    substituteInPlace build-logic/build-platform/build.gradle.kts \
      --replace-fail 'val kotlinVersion = providers.gradleProperty("buildKotlinVersion")' $'val kotlinVersion = "1.8.10"\n// bootstrap from M4 would otherwise drag this back to 1.7.10 via embeddedKotlinVersion' \
      --replace-fail '    .getOrElse(embeddedKotlinVersion)' ""
    substituteInPlace build-logic/build-platform/build.gradle.kts \
      --replace-fail '        api("org.gradle:test-retry-gradle-plugin:1.5.0")' '        api("org.gradle:test-retry-gradle-plugin:1.4.0")'
    substituteInPlace build-logic/performance-testing/build.gradle.kts \
      --replace-fail '    classpath += files(tasks.compileGroovy)' '    libraries.from(files(tasks.compileGroovy))'
    printf '\n\ntasks.withType<org.jetbrains.kotlin.gradle.tasks.KotlinCompile>().configureEach {\n    kotlinOptions.jvmTarget = "1.8"\n}\n\ntasks.withType<JavaCompile>().configureEach {\n    options.release.set(8)\n}\n' >> build-logic/performance-testing/build.gradle.kts
    substituteInPlace build-logic-commons/gradle-plugin/src/main/kotlin/gradlebuild/StringExtensions.kt \
      --replace-fail '    lowercase(Locale.US)' '    toLowerCase(Locale.US)'
    substituteInPlace build-logic-commons/gradle-plugin/src/main/kotlin/gradlebuild/StringExtensions.kt \
      --replace-fail '    uppercase(Locale.US)' '    toUpperCase(Locale.US)'
    substituteInPlace build-logic-commons/gradle-plugin/src/main/kotlin/gradlebuild/StringExtensions.kt \
      --replace-fail '    replaceFirstChar { it.uppercase(Locale.US) }' '    if (isEmpty()) this else substring(0, 1).toUpperCase(Locale.US) + substring(1)'
    substituteInPlace build-logic-commons/gradle-plugin/src/main/kotlin/gradlebuild/StringExtensions.kt \
      --replace-fail '    replaceFirstChar { it.lowercase(Locale.US) }' '    if (isEmpty()) this else substring(0, 1).toLowerCase(Locale.US) + substring(1)'
    substituteInPlace subprojects/kotlin-dsl/src/main/kotlin/org/gradle/kotlin/dsl/precompile/v1/PrecompiledScriptTemplates.kt \
      --replace-fail 'import kotlin.script.experimental.api.isStandalone' "" \
      --replace-fail '    isStandalone(false)' ""
    substituteInPlace subprojects/kotlin-dsl/src/main/kotlin/org/gradle/kotlin/dsl/support/KotlinCompiler.kt \
      --replace-fail 'import org.jetbrains.kotlin.compiler.plugin.ComponentRegistrar' $'import org.jetbrains.kotlin.compiler.plugin.ComponentRegistrar\nimport org.jetbrains.kotlin.compiler.plugin.ExperimentalCompilerApi' \
      --replace-fail $'private\nfun CompilerConfiguration.addScriptingCompilerComponents() {' $'@OptIn(ExperimentalCompilerApi::class)\nprivate\nfun CompilerConfiguration.addScriptingCompilerComponents() {'
  '';
}
