{
  jdk8_headless,
  jdk11_headless,
  jdk17_headless,
  jdk21_headless,
  gradle_8_0,
  gradle-from-source,
  mergeLock,
}:
gradle-from-source {
  version = "8.1-20230203";
  rev = "443ad4b46d5d6f364f5431e9a47eb87d65abf1d6";
  hash = "sha256-KYbibckAHehS3Ebt07ddJ0FGe+LO0mU2yAo6DFFIVaA=";
  patches = [
    ./kotlin-dsl-assignment-compat.patch
  ];
  lockFile = mergeLock [
    gradle_8_0.unwrapped.passthru.lockFile
    ../gradle_8_1/more.gradle.lock
  ];
  defaultJava = jdk21_headless;
  buildJdk = jdk11_headless;
  javaToolchains = [
    jdk8_headless
    jdk11_headless
    jdk17_headless
  ];
  bootstrapGradle = gradle_8_0;
  postPatch = ''
    substituteInPlace subprojects/build-scan-performance/build.gradle.kts \
      --replace-fail \
      'performanceTest.registerTestProject<gradlebuild.performance.generator.tasks.JvmProjectGeneratorTask>("javaProject") {' \
      'performanceTest.registerTestProject("javaProject", gradlebuild.performance.generator.tasks.JvmProjectGeneratorTask::class.java) {'
    for file in \
      build-logic/jvm/src/main/kotlin/gradlebuild.unittest-and-compile.gradle.kts \
      build-logic-commons/code-quality-rules/build.gradle.kts \
      build-logic-commons/commons/build.gradle.kts \
      build-logic-commons/commons/src/main/kotlin/common.kt \
      build-logic-commons/gradle-plugin/build.gradle.kts \
      subprojects/docs/src/snippets/java/toolchain-filters/groovy/build.gradle \
      subprojects/docs/src/snippets/java/toolchain-filters/kotlin/build.gradle.kts \
      subprojects/platform-jvm/src/integTest/groovy/org/gradle/jvm/toolchain/JavaToolchainDownloadIntegrationTest.groovy
    do
      if [ -f "$file" ] && grep -Fq 'vendor = JvmVendorSpec.ADOPTIUM' "$file"; then
        substituteInPlace "$file" --replace-fail 'vendor = JvmVendorSpec.ADOPTIUM' ""
      fi
      if [ -f "$file" ] && grep -Fq 'vendor.set(JvmVendorSpec.ADOPTIUM)' "$file"; then
        substituteInPlace "$file" --replace-fail 'vendor.set(JvmVendorSpec.ADOPTIUM)' ""
      fi
    done
  '';
}
