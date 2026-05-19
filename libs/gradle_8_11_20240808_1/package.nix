# this is before gradle v8.11.0-M1. before commit https://github.com/gradle/gradle/commit/370ef936bf8edd86bc881ad1f54229c164f2e67f
{
  jdk8_headless,
  jdk11_headless,
  jdk17_headless,
  jdk21_headless,
  gradle_8_11_20240807,
  gradle-from-source,
  runCommand,
  jq,
  lib,
  mergeLock,
}:
gradle-from-source {
  version = "8.11-20240808-1";
  rev = "e69fb10f926324a9f861515ddf0c80419b24b899";
  hash = "sha256-FBK/ROz5YmETf4M+vEVYrBxJiDo08lTW3bp3h4WgN3g=";
  # org.jetbrains.kotlinx:kotlinx-metadata-jvm:0.7.0 org.jetbrains.kotlinx:kotlinx-metadata-jvm:0.7.0 org.jetbrains.kotlin:kotlin-scripting-compiler-impl-embeddable:2.0.0 org.gradle.buildtool.internal:configuration-cache-report:1.11
  lockFile = mergeLock [
    gradle_8_11_20240807.unwrapped.passthru.lockFile
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
      platforms/documentation/docs/src/snippets/java/toolchain-filters/groovy/build.gradle \
      platforms/documentation/docs/src/snippets/java/toolchain-filters/kotlin/build.gradle.kts \
      platforms/jvm/language-java/src/integTest/groovy/org/gradle/jvm/toolchain/JavaToolchainDownloadIntegrationTest.groovy
    do
      if [ -f "$file" ] && grep -Fq 'vendor = JvmVendorSpec.ADOPTIUM' "$file"; then
        substituteInPlace "$file" --replace-fail 'vendor = JvmVendorSpec.ADOPTIUM' ""
      fi
    done
  '';
  bootstrapGradle = gradle_8_11_20240807;
}
