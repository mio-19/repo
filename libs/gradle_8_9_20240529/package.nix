# before https://github.com/gradle/gradle/commit/7f8365f4a6492eb0e8acbbb37be1f30352ebbaa6
{
  jdk8_headless,
  jdk11_headless,
  jdk17_headless,
  jdk21_headless,
  gradle-from-source,
  mergeLock,
  gradle_8_9_20240411,
}:
gradle-from-source {
  version = "8.9.0-20240529";
  rev = "8a9cda36b91f1b7f66d0c2c27e5594a210bac8f3";
  hash = "sha256-IplC2CQp/ZWMn37fUByaHF9/X04Ey4Q4vfmFaPXCqQA=";
  # [id: 'com.gradle.develocity', version: '3.17.4']
  lockFile = mergeLock [
    gradle_8_9_20240411.unwrapped.passthru.lockFile
    ./more.gradle.lock
    # [id: 'org.gradle.kotlin.kotlin-dsl', version: '4.4.0']
    ../gradle_8_9_rc1/gradle.lock
  ];
  defaultJava = jdk21_headless;
  buildJdk = jdk11_headless;
  javaToolchains = [
    jdk8_headless
    jdk11_headless
    jdk17_headless
  ];
  bootstrapGradle = gradle_8_9_20240411;
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
}
