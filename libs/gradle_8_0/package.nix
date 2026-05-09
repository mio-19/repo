{
  temurin-bin-8,
  temurin-bin-11,
  temurin-bin-17,
  jdk21_headless,
  gradle_8_0_M5,
  gradle-from-source,
  mergeLock,
}:
gradle-from-source {
  version = "8.0";
  hash = "sha256-p9woCn+o3hkTMFg5d11jjtILS+iLdAmSeQB59t3+QzA=";
  patches = [
    ./kotlin-dsl-assignment-compat.patch
  ];
  lockFile = mergeLock [
    gradle_8_0_M5.unwrapped.passthru.lockFile
    ./more.gradle.lock
    ../gradle_8_0_M6/more.gradle.lock
  ];
  defaultJava = jdk21_headless;
  # this version specifically ask for termurin branded jdk.
  buildJdk = temurin-bin-11;
  javaToolchains = [
    temurin-bin-8
    temurin-bin-11
    temurin-bin-17
  ];
  bootstrapGradle = gradle_8_0_M5;
  postPatch = ''
    substituteInPlace settings.gradle.kts \
      --replace-fail 'id("com.gradle.enterprise").version("3.12.3")' 'id("com.gradle.enterprise").version("3.11.2")' \
      --replace-fail 'id("org.gradle.toolchains.foojay-resolver-convention") version("0.4.0")' ""
    substituteInPlace build-logic-settings/settings.gradle.kts \
      build-logic-commons/settings.gradle.kts \
      build-logic/settings.gradle.kts \
      --replace-fail 'id("org.gradle.toolchains.foojay-resolver-convention") version("0.4.0")' ""
    substituteInPlace build-logic/build-platform/build.gradle.kts \
      --replace-fail 'api("com.gradle:gradle-enterprise-gradle-plugin:3.12.3")' 'api("com.gradle:gradle-enterprise-gradle-plugin:3.11.2")' \
      --replace-fail '        api("org.asciidoctor:asciidoctor-gradle-jvm:3.3.2")' $'        api("org.asciidoctor:asciidoctor-gradle-jvm:3.3.2")\n        api("org.gradle:test-retry-gradle-plugin:1.4.0")'
    substituteInPlace build-logic-commons/gradle-plugin/build.gradle.kts \
      --replace-fail 'compileOnly("com.gradle:gradle-enterprise-gradle-plugin:3.12.3")' 'compileOnly("com.gradle:gradle-enterprise-gradle-plugin:3.11.2")'
    substituteInPlace build-logic/basics/src/main/kotlin/gradlebuild/basics/tasks/PackageListGenerator.kt \
      --replace-fail "                        bufferedWriter.write('\\n'.code)" "                        bufferedWriter.write('\\n'.toInt())"
    substituteInPlace build-logic/performance-testing/build.gradle.kts \
      --replace-fail '    implementation("javax.xml.bind:jaxb-api")' $'    implementation("javax.xml.bind:jaxb-api")\n    implementation("org.gradle:test-retry-gradle-plugin")'
    substituteInPlace build-logic/performance-testing/src/main/kotlin/gradlebuild/performance/PerformanceTestPlugin.kt \
      --replace-fail 'import com.gradle.enterprise.gradleplugin.testretry.retry' ""
    substituteInPlace build-logic/jvm/build.gradle.kts \
      --replace-fail '    implementation("com.google.code.gson:gson")' $'    implementation("com.google.code.gson:gson")\n    implementation("org.gradle:test-retry-gradle-plugin")'
    substituteInPlace build-logic/jvm/src/main/kotlin/gradlebuild.unittest-and-compile.gradle.kts \
      --replace-fail 'import com.gradle.enterprise.gradleplugin.testretry.retry' "" \
      --replace-fail '    id("gradlebuild.dependency-modules")' $'    id("gradlebuild.dependency-modules")\n    id("org.gradle.test-retry")'
    substituteInPlace subprojects/kotlin-dsl/src/main/kotlin/org/gradle/kotlin/dsl/precompile/v1/PrecompiledScriptTemplates.kt \
      --replace-fail 'import kotlin.script.experimental.api.isStandalone' "" \
      --replace-fail '    isStandalone(false)' ""
    substituteInPlace subprojects/kotlin-dsl/src/main/kotlin/org/gradle/kotlin/dsl/support/KotlinCompiler.kt \
      --replace-fail 'import org.jetbrains.kotlin.compiler.plugin.ExperimentalCompilerApi' "" \
      --replace-fail 'import org.jetbrains.kotlin.config.JVMConfigurationKeys.IR' "" \
      --replace-fail 'import org.jetbrains.kotlin.config.JVMConfigurationKeys.SAM_CONVERSIONS' "" \
      --replace-fail 'import org.jetbrains.kotlin.config.JvmClosureGenerationScheme' "" \
      --replace-fail 'import org.jetbrains.kotlin.config.JvmTarget.JVM_19' "" \
      --replace-fail '    jvmTarget: JavaVersion,' "" \
      --replace-fail '    jvmTarget,' "" \
      --replace-fail '            val configuration = compilerConfigurationFor(messageCollector, jvmTarget).apply {' '            val configuration = compilerConfigurationFor(messageCollector).apply {' \
      --replace-fail 'fun compilerConfigurationFor(messageCollector: MessageCollector, jvmTarget: JavaVersion): CompilerConfiguration =' 'fun compilerConfigurationFor(messageCollector: MessageCollector): CompilerConfiguration =' \
      --replace-fail '        put(JVM_TARGET, jvmTarget.toKotlinJvmTarget())' '        put(JVM_TARGET, JVM_1_8)' \
      --replace-fail '        put(IR, true)' "" \
      --replace-fail '        put(SAM_CONVERSIONS, JvmClosureGenerationScheme.CLASS)' "" \
      --replace-fail '        put(CommonConfigurationKeys.ALLOW_ANY_SCRIPTS_IN_SOURCE_ROOTS, true)' "" \
      --replace-fail '        else JVM_19' '        else JVM_1_8' \
      --replace-fail '    languageVersion = LanguageVersion.KOTLIN_1_8,' '    languageVersion = LanguageVersion.KOTLIN_1_4,' \
      --replace-fail '    apiVersion = ApiVersion.KOTLIN_1_8,' '    apiVersion = ApiVersion.KOTLIN_1_4,' \
      --replace-fail '        LanguageFeature.TypeEnhancementImprovementsInStrictMode to LanguageFeature.State.DISABLED,' "" \
      --replace-fail '@OptIn(ExperimentalCompilerApi::class)' ""
    substituteInPlace subprojects/kotlin-dsl/src/main/kotlin/org/gradle/kotlin/dsl/codegen/ApiExtensionsJar.kt \
      --replace-fail 'import org.gradle.kotlin.dsl.support.bytecode.GradleJvmVersion' "" \
      --replace-fail '        GradleJvmVersion.minimalJavaVersion,' ""
    substituteInPlace subprojects/kotlin-dsl/src/main/kotlin/org/gradle/kotlin/dsl/execution/ResidualProgramCompiler.kt \
      --replace-fail '                jvmTarget,' ""
    substituteInPlace subprojects/kotlin-dsl-provider-plugins/src/main/kotlin/org/gradle/kotlin/dsl/provider/plugins/precompiled/DefaultPrecompiledScriptPluginsSupport.kt \
      --replace-fail '            jvmTarget.set(jvmTargetProvider)' '            jvmTarget.set(JavaVersion.VERSION_11)'
    substituteInPlace subprojects/kotlin-dsl-provider-plugins/src/main/kotlin/org/gradle/kotlin/dsl/provider/plugins/precompiled/tasks/CompilePrecompiledScriptPluginPlugins.kt \
      --replace-fail '                    resolveJvmTarget(),' "" \
      --replace-fail '                    kotlinModuleName,' '                    kotlinModuleName,'
    substituteInPlace subprojects/kotlin-dsl/src/main/kotlin/org/gradle/kotlin/dsl/support/KotlinCompiler.kt \
      --replace-fail 'import org.jetbrains.kotlin.compiler.plugin.ComponentRegistrar' $'import org.jetbrains.kotlin.compiler.plugin.ComponentRegistrar\nimport org.jetbrains.kotlin.compiler.plugin.ExperimentalCompilerApi' \
      --replace-fail $'private\nfun CompilerConfiguration.addScriptingCompilerComponents() {' $'@OptIn(ExperimentalCompilerApi::class)\nprivate\nfun CompilerConfiguration.addScriptingCompilerComponents() {'
    substituteInPlace subprojects/kotlin-dsl/src/test/kotlin/org/gradle/kotlin/dsl/normalization/KotlinApiClassExtractorTest.kt \
      --replace-fail '            JavaVersion.current(),' ""
    substituteInPlace subprojects/kotlin-dsl/src/test/kotlin/org/gradle/kotlin/dsl/accessors/ProjectAccessorsClassPathTest.kt \
      --replace-fail '                JavaVersion.current(),' ""
    substituteInPlace subprojects/kotlin-dsl/src/test/kotlin/org/gradle/kotlin/dsl/accessors/KotlinMetadataIntegrationTest.kt \
      --replace-fail '                JavaVersion.current(),' ""
    substituteInPlace subprojects/kotlin-dsl/src/test/kotlin/org/gradle/kotlin/dsl/integration/KotlinScriptCompilerTest.kt \
      --replace-fail '            JavaVersion.current(),' ""
    for f in build-logic/*/build.gradle.kts build-logic-commons/*/build.gradle.kts build-logic-settings/*/build.gradle.kts; do
      if [ -f "$f" ]; then
        if grep -Eq '`kotlin-dsl`|gradlebuild\.build-logic\.kotlin-dsl-gradle-plugin' "$f"; then
          printf '\n\nkotlinDslPluginOptions {\n    jvmTarget.set("11")\n}\n' >> "$f"
        fi
      fi
    done
    printf '\n\ntasks.withType<org.jetbrains.kotlin.gradle.tasks.KotlinCompile>().configureEach {\n    kotlinOptions.jvmTarget = "11"\n}\n' >> build-logic/cleanup/build.gradle.kts
    printf '\n\ntasks.withType<org.jetbrains.kotlin.gradle.tasks.KotlinCompile>().configureEach {\n    kotlinOptions.jvmTarget = "11"\n}\n' >> build-logic/binary-compatibility/build.gradle.kts
    printf '\n\ntasks.withType<org.jetbrains.kotlin.gradle.tasks.KotlinCompile>().configureEach {\n    kotlinOptions.jvmTarget = "11"\n}\n' >> build-logic/performance-testing/build.gradle.kts
    substituteInPlace build-logic-commons/gradle-plugin/src/main/kotlin/gradlebuild/StringExtensions.kt \
      --replace-fail '    lowercase(Locale.US)' '    toLowerCase(Locale.US)'
    substituteInPlace build-logic-commons/gradle-plugin/src/main/kotlin/gradlebuild/StringExtensions.kt \
      --replace-fail '    uppercase(Locale.US)' '    toUpperCase(Locale.US)'
    substituteInPlace build-logic-commons/gradle-plugin/src/main/kotlin/gradlebuild/StringExtensions.kt \
      --replace-fail '    replaceFirstChar { it.uppercase(Locale.US) }' '    if (isEmpty()) this else substring(0, 1).toUpperCase(Locale.US) + substring(1)'
    substituteInPlace build-logic-commons/gradle-plugin/src/main/kotlin/gradlebuild/StringExtensions.kt \
      --replace-fail '    replaceFirstChar { it.lowercase(Locale.US) }' '    if (isEmpty()) this else substring(0, 1).toLowerCase(Locale.US) + substring(1)'
  '';
}
