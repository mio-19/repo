# this is before gradle v8.11.0-M1. before commit https://github.com/gradle/gradle/commit/f42b8312af060441d37ccde7b7ff9449d15aeaa9
{
  jdk8_headless,
  jdk11_headless,
  jdk17_headless,
  jdk21_headless,
  gradle_8_11_20240905_1,
  gradle_8_11_20240906,
  gradle-from-source,
  mergeLock,
}:
gradle-from-source {
  version = "8.11-20240911";
  rev = "b833359025724eaa4bef438b54d6277c9d5da4ff";
  hash = "sha256-WI4+JnQorP9HTJ/kCzgNzp6mfiWMzwrM/r3uZ5VA3qE=";
  lockFile = mergeLock [
    gradle_8_11_20240906.unwrapped.passthru.lockFile
    # org.gradle.buildtool.internal:configuration-cache-report:1.16
    ./more.gradle.lock
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
      build-logic-commons/basics/build.gradle.kts \
      build-logic-commons/code-quality-rules/build.gradle.kts \
      build-logic-commons/gradle-plugin/build.gradle.kts \
      build-logic-commons/gradle-plugin/src/main/kotlin/gradlebuild/commons/JavaPluginExtensions.kt \
      build-logic-commons/module-identity/build.gradle.kts \
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
  # bootstrap chain skip; standalone build still uses gradle_8_11_20240906
  bootstrapGradle = gradle_8_11_20240905_1;
}
