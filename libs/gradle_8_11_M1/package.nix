{
  jdk8_headless,
  jdk11_headless,
  jdk17_headless,
  jdk21_headless,
  gradle_8_11_20240920_1,
  gradle-from-source,
  mergeLock,
}:
gradle-from-source {
  version = "8.11.0-M1";
  hash = "sha256-+0ijcrkUCFa1JTNM0rEEXgYuz0sZfHBdR4eWl5H2iDg=";
  lockFile = mergeLock [
    gradle_8_11_20240920_1.unwrapped.passthru.lockFile
    # org.gradle.buildtool.internal:configuration-cache-report:1.21
    ../gradle_8_12_20241015/gradle.lock
  ];
  defaultJava = jdk21_headless;
  buildJdk = jdk11_headless;
  javaToolchains = [
    jdk8_headless
    jdk11_headless
    jdk17_headless
  ];
  postPatch = ''
    for file in \
      build-logic-settings/build-environment/build.gradle.kts \
      build-logic/jvm/src/main/kotlin/gradlebuild.unittest-and-compile.gradle.kts \
      build-logic-commons/gradle-plugin/src/main/kotlin/gradlebuild/commons/JavaPluginExtensions.kt \
      build-logic-commons/settings.gradle.kts \
      platforms/documentation/docs/src/snippets/java/toolchain-filters/groovy/build.gradle \
      platforms/documentation/docs/src/snippets/java/toolchain-filters/kotlin/build.gradle.kts \
      platforms/jvm/language-java/src/integTest/groovy/org/gradle/jvm/toolchain/JavaToolchainDownloadIntegrationTest.groovy
    do
      if [ -f "$file" ] && grep -Fq 'vendor = JvmVendorSpec.ADOPTIUM' "$file"; then
        substituteInPlace "$file" --replace-fail 'vendor = JvmVendorSpec.ADOPTIUM' ""
      fi
    done
  '';
  bootstrapGradle = gradle_8_11_20240920_1;
}
