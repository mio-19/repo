{
  jdk8_headless,
  jdk11_headless,
  jdk17_headless,
  jdk21_headless,
  gradle_8_0_M3,
  gradle_8_0_20220911,
  gradle-from-source,
  mergeLock,
}:
gradle-from-source {
  version = "8.0.0-M4";
  tag = "v8.0.0-M4";
  hash = "sha256-c+E5lIDoLs1TSu+7JUHfH/QIdnpJjpcnWZegYT+m2u4=";
  lockFile = mergeLock [
    gradle_8_0_M3.unwrapped.passthru.lockFile
    gradle_8_0_20220911.unwrapped.passthru.lockFile
    ../gradle_8_0/more.gradle.lock
    ../gradle_7_6_rc1/more.gradle.lock
    ../gradle_7_6_rc4/more.gradle.lock
  ];
  defaultJava = jdk21_headless;
  # gradle-from-source strips upstream Adoptium toolchain vendor requirements.
  buildJdk = jdk11_headless;
  javaToolchains = [
    jdk8_headless
    jdk11_headless
    jdk17_headless
  ];
  bootstrapGradle = gradle_8_0_M3;
  postPatch = ''
    substituteInPlace build-logic-commons/gradle-plugin/build.gradle.kts \
      --replace-fail 'implementation("org.gradle.kotlin.kotlin-dsl:org.gradle.kotlin.kotlin-dsl.gradle.plugin:3.2.2")' 'implementation("org.gradle.kotlin.kotlin-dsl:org.gradle.kotlin.kotlin-dsl.gradle.plugin:3.1.0")' \
      --replace-fail 'implementation("org.jetbrains.kotlin:kotlin-gradle-plugin:1.7.22")' 'implementation("org.jetbrains.kotlin:kotlin-gradle-plugin:1.7.10")'
    substituteInPlace build-logic/kotlin-dsl/src/main/kotlin/gradlebuild.kotlin-dsl-dependencies-embedded.gradle.kts \
      --replace-fail 'val publishedKotlinDslPluginVersion = "3.2.2" // TODO:kotlin-dsl' 'val publishedKotlinDslPluginVersion = "3.1.0" // TODO:kotlin-dsl'
    substituteInPlace build-logic/dependency-modules/src/main/kotlin/gradlebuild/modules/extension/ExternalModulesExtension.kt \
      --replace-fail '    val kotlinVersion = "1.7.22"' '    val kotlinVersion = "1.7.10"'
  '';
}
