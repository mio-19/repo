{
  jdk8_headless,
  jdk11_headless,
  jdk17_headless,
  jdk21_headless,
  gradle_8_3_20230705,
  gradle-from-source,
  mergeLock,
}:
gradle-from-source {
  version = "8.3.0-20230706";
  rev = "379ea598b9025616cce030ea23986545074cb0c9";
  hash = "sha256-ymgQinxzJ8of+gXsA2c38qdqOKPC6He2RTWpURVa1rU=";
  lockFile = mergeLock [
    gradle_8_3_20230705.unwrapped.passthru.lockFile
    ./gradle.lock
  ];
  defaultJava = jdk21_headless;
  buildJdk = jdk11_headless;
  javaToolchains = [
    jdk8_headless
    jdk11_headless
    jdk17_headless
  ];
  bootstrapGradle = gradle_8_3_20230705;
  postPatch = ''
    for file in \
      build-logic-settings/build-environment/build.gradle.kts \
      build-logic/jvm/src/main/kotlin/gradlebuild.unittest-and-compile.gradle.kts \
      build-logic-commons/basics/build.gradle.kts \
      build-logic-commons/code-quality-rules/build.gradle.kts \
      build-logic-commons/commons/build.gradle.kts \
      build-logic-commons/commons/src/main/kotlin/common.kt \
      build-logic-commons/gradle-plugin/build.gradle.kts \
      build-logic-commons/gradle-plugin/src/main/kotlin/gradlebuild/commons/JavaPluginExtensions.kt \
      build-logic-commons/module-identity/build.gradle.kts \
      platforms/documentation/docs/src/snippets/java/toolchain-filters/groovy/build.gradle \
      platforms/documentation/docs/src/snippets/java/toolchain-filters/kotlin/build.gradle.kts \
      platforms/jvm/language-java/src/integTest/groovy/org/gradle/jvm/toolchain/JavaToolchainDownloadIntegrationTest.groovy \
      subprojects/docs/src/snippets/java/toolchain-filters/groovy/build.gradle \
      subprojects/docs/src/snippets/java/toolchain-filters/kotlin/build.gradle.kts \
      subprojects/platform-jvm/src/integTest/groovy/org/gradle/jvm/toolchain/JavaToolchainDownloadIntegrationTest.groovy
    do
      if [ -f "$file" ] && grep -Fq 'vendor = JvmVendorSpec.ADOPTIUM' "$file"; then
        substituteInPlace "$file" --replace-fail 'vendor = JvmVendorSpec.ADOPTIUM' ""
      fi
    done
  '';
}
