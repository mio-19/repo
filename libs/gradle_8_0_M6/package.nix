{
  temurin-bin-8,
  temurin-bin-11,
  temurin-bin-17,
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
      --replace-fail 'id("com.gradle.enterprise").version("3.12")' 'id("com.gradle.enterprise").version("3.12.3")'
    substituteInPlace build-logic/build-platform/build.gradle.kts \
      --replace-fail 'api("com.gradle:gradle-enterprise-gradle-plugin:3.12")' 'api("com.gradle:gradle-enterprise-gradle-plugin:3.12.3")'
    substituteInPlace build-logic-commons/gradle-plugin/build.gradle.kts \
      --replace-fail 'compileOnly("com.gradle:gradle-enterprise-gradle-plugin:3.12")' 'compileOnly("com.gradle:gradle-enterprise-gradle-plugin:3.12.3")'
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
    substituteInPlace subprojects/kotlin-dsl-provider-plugins/src/main/kotlin/org/gradle/kotlin/dsl/provider/plugins/precompiled/tasks/CompilePrecompiledScriptPluginPlugins.kt \
      --replace-fail 'import org.gradle.api.tasks.Nested' "" \
      --replace-fail 'import org.gradle.api.tasks.Optional' "" \
      --replace-fail 'import org.gradle.jvm.toolchain.JavaLauncher' "" \
      --replace-fail '    @get:Nested' "" \
      --replace-fail '    abstract val javaLauncher: Property<JavaLauncher>' "" \
      --replace-fail '    @Deprecated("Configure a Java Toolchain instead")' "" \
      --replace-fail '                    resolveJvmTarget(),' '                    jvmTarget.get(),' \
      --replace-fail $'\n    private\n    fun resolveJvmTarget(): JavaVersion =\n        if (jvmTarget.isPresent) jvmTarget.get()\n        else JavaVersion.toVersion(javaLauncher.get().metadata.languageVersion.asInt())' ""
    substituteInPlace subprojects/kotlin-dsl-provider-plugins/src/main/kotlin/org/gradle/kotlin/dsl/provider/plugins/precompiled/DefaultPrecompiledScriptPluginsSupport.kt \
      --replace-fail 'import org.gradle.api.plugins.JavaPluginExtension' "" \
      --replace-fail 'import org.gradle.jvm.toolchain.JavaToolchainService' "" \
      --replace-fail '            javaLauncher.set(javaToolchainService.launcherFor(java.toolchain))' "" \
      --replace-fail $'\n\nprivate\nval Project.javaToolchainService\n    get() = serviceOf<JavaToolchainService>()\n\n\nprivate\nval Project.java\n    get() = the<JavaPluginExtension>()' ""
  '';
}
