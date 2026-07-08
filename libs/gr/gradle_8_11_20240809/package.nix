# this is before gradle v8.11.0-M1. before commit https://github.com/gradle/gradle/commit/61c49a2eeb032508adf2a2e22c90bfb9ac09d77e
{
  jdk8_headless,
  jdk11_headless,
  jdk17_headless,
  jdk21_headless,
  gradle_8_11_20240808_2,
  gradle-from-source,
  mergeLock,
  jq,
  lib,
}:
gradle-from-source {
  version = "8.11-20240809";
  rev = "d40cb09ed3c2f557ee731dd88dde0cae2f3f0ce1";
  hash = "sha256-xt5RLWbM1YAgg0IAl7OttqV1qjxpWzyRmQdGKjTXmr0=";
  # more.gradle.lock: org.gradle.kotlin.kotlin-dsl:org.gradle.kotlin.kotlin-dsl.gradle.plugin:5.1.0 org.jetbrains.kotlin:kotlin-gradle-plugin:2.0.10 org.jetbrains.kotlin:kotlin-util-io:2.0.10 org.jetbrains.kotlinx:kotlinx-metadata-jvm:0.7.0
  # ./refresh-hashes.sh more.gradle.lock
  lockFile = mergeLock [
    gradle_8_11_20240808_2.unwrapped.passthru.lockFile
    ../gradle_8_11/gradle.lock
    ./more.gradle.lock
    ../gradle_8_11_1/gradle.lock
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
  bootstrapGradle = gradle_8_11_20240808_2;
}
