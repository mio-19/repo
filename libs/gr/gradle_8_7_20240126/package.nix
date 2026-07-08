# before https://github.com/gradle/gradle/commit/edde41dec57b90b08d3172130eb71a991f61464c
{
  jdk8_headless,
  jdk11_headless,
  jdk17_headless,
  jdk21_headless,
  gradle_8_7_20240118_1,
  gradle_8_7_20240118_3,
  gradle-from-source,
  mergeLock,
}:
gradle-from-source {
  version = "8.7.0-20240126";
  rev = "6b5635d02c7fb6a663797dcbd3f40e779b8fc989";
  hash = "sha256-OBRUIBqp2eJRJrySttyO53vn20S/ZMqsyZ1zMkm07MA=";
  lockFile = mergeLock [
    gradle_8_7_20240118_3.unwrapped.passthru.lockFile
  ];
  defaultJava = jdk21_headless;
  buildJdk = jdk11_headless;
  javaToolchains = [
    jdk8_headless
    jdk11_headless
    jdk17_headless
  ];
  # bootstrap chain skip; standalone build still uses gradle_8_7_20240118_3
  bootstrapGradle = gradle_8_7_20240118_1;
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
