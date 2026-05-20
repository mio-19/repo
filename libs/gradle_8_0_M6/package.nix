{
  jdk8_headless,
  jdk11_headless,
  jdk17_headless,
  jdk21_headless,
  gradle_8_0_M5,
  gradle_8_0_20220911,
  gradle-from-source,
  mergeLock,
}:
gradle-from-source {
  version = "8.0.0-M6";
  tag = "v8.0.0-M6";
  hash = "sha256-6qaKuemw6ZSj4avmViFoe1pX5Rmi+jkGwNtn3gkoKFs=";
  lockFile = mergeLock [
    gradle_8_0_M5.unwrapped.passthru.lockFile
    gradle_8_0_20220911.unwrapped.passthru.lockFile
    ../gradle_8_0/more.gradle.lock
    ../gradle_7_6_rc1/more.gradle.lock
    ./more.gradle.lock
  ];
  defaultJava = jdk21_headless;
  # this version specifically ask for Temurin branded jdk.
  relaxJavaVendor = true;
  buildJdk = jdk11_headless;
  javaToolchains = [
    jdk8_headless
    jdk11_headless
    jdk17_headless
  ];
  bootstrapGradle = gradle_8_0_M5;
  postPatch = ''
    substituteInPlace settings.gradle.kts \
      --replace-fail 'id("com.gradle.enterprise").version("3.12")' 'id("com.gradle.enterprise").version("3.12.3")'
    substituteInPlace build-logic/build-platform/build.gradle.kts \
      --replace-fail 'api("com.gradle:gradle-enterprise-gradle-plugin:3.12")' 'api("com.gradle:gradle-enterprise-gradle-plugin:3.12.3")'
    substituteInPlace build-logic/build-platform/build.gradle.kts \
      --replace-fail 'val kotlinVersion = providers.gradleProperty("buildKotlinVersion")' $'val kotlinVersion = "1.8.10"\n// bootstrap from M5 would otherwise drag this back to 1.7.22 via embeddedKotlinVersion' \
      --replace-fail '    .getOrElse(embeddedKotlinVersion)' "" \
      --replace-fail '        api("org.gradle:test-retry-gradle-plugin:1.5.0")' '        api("org.gradle:test-retry-gradle-plugin:1.4.0")'
    substituteInPlace build-logic-commons/gradle-plugin/build.gradle.kts \
      --replace-fail 'compileOnly("com.gradle:gradle-enterprise-gradle-plugin:3.12")' 'compileOnly("com.gradle:gradle-enterprise-gradle-plugin:3.12.3")' \
      --replace-fail 'implementation("org.gradle.kotlin.kotlin-dsl:org.gradle.kotlin.kotlin-dsl.gradle.plugin:3.2.7")' 'implementation("org.gradle.kotlin.kotlin-dsl:org.gradle.kotlin.kotlin-dsl.gradle.plugin:4.0.6")' \
      --replace-fail 'implementation("org.jetbrains.kotlin:kotlin-gradle-plugin:1.7.22")' 'implementation("org.jetbrains.kotlin:kotlin-gradle-plugin:1.8.10")'
    substituteInPlace build-logic/kotlin-dsl/src/main/kotlin/gradlebuild.kotlin-dsl-dependencies-embedded.gradle.kts \
      --replace-fail 'val publishedKotlinDslPluginVersion = "3.2.7" // TODO:kotlin-dsl' 'val publishedKotlinDslPluginVersion = "4.0.6" // TODO:kotlin-dsl'
    substituteInPlace build-logic/dependency-modules/src/main/kotlin/gradlebuild/modules/extension/ExternalModulesExtension.kt \
      --replace-fail '    val kotlinVersion = "1.7.22"' '    val kotlinVersion = "1.8.10"'
    substituteInPlace build-logic/performance-testing/build.gradle.kts \
      --replace-fail '    classpath += files(tasks.compileGroovy)' '    libraries.from(files(tasks.compileGroovy))'
    printf '\n\ntasks.withType<org.jetbrains.kotlin.gradle.tasks.KotlinCompile>().configureEach {\n    kotlinOptions.jvmTarget = "11"\n}\n\ntasks.withType<JavaCompile>().configureEach {\n    options.release.set(11)\n}\n' >> build-logic/performance-testing/build.gradle.kts
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
    substituteInPlace subprojects/kotlin-dsl-provider-plugins/src/main/kotlin/org/gradle/kotlin/dsl/provider/plugins/precompiled/tasks/CompilePrecompiledScriptPluginPlugins.kt \
      --replace-fail 'import org.gradle.jvm.toolchain.JavaLauncher' "" \
      --replace-fail 'import org.gradle.api.tasks.Nested' "" \
      --replace-fail $'\n    @get:Nested\n    internal\n    abstract val javaLauncher: Property<JavaLauncher>\n' "" \
      --replace-fail '    @Deprecated("Configure a Java Toolchain instead")' "" \
      --replace-fail '                    resolveJvmTarget(),' '                    jvmTarget.get(),' \
      --replace-fail $'\n    private\n    fun resolveJvmTarget(): JavaVersion =\n        if (jvmTarget.isPresent) jvmTarget.get()\n        else JavaVersion.toVersion(javaLauncher.get().metadata.languageVersion.asInt())' ""
    for f in build-logic/*/build.gradle.kts build-logic-commons/*/build.gradle.kts build-logic-settings/*/build.gradle.kts; do
      if [ -f "$f" ]; then
        if grep -Eq '`kotlin-dsl`|gradlebuild\.build-logic\.kotlin-dsl-gradle-plugin' "$f"; then
          printf '\n\nkotlinDslPluginOptions {\n    jvmTarget.set("11")\n}\n' >> "$f"
        fi
      fi
    done
    substituteInPlace subprojects/kotlin-dsl-provider-plugins/src/main/kotlin/org/gradle/kotlin/dsl/provider/plugins/precompiled/DefaultPrecompiledScriptPluginsSupport.kt \
      --replace-fail 'import org.gradle.api.plugins.JavaPluginExtension' "" \
      --replace-fail 'import org.gradle.jvm.toolchain.JavaToolchainService' "" \
      --replace-fail '            jvmTarget.set(jvmTargetProvider)' '            jvmTarget.set(jvmTargetProvider.orElse(JavaVersion.VERSION_1_8))' \
      --replace-fail '            javaLauncher.set(javaToolchainService.launcherFor(java.toolchain))' "" \
      --replace-fail $'\n\nprivate\nval Project.javaToolchainService\n    get() = serviceOf<JavaToolchainService>()\n\n\nprivate\nval Project.java\n    get() = the<JavaPluginExtension>()' ""
  '';
}
