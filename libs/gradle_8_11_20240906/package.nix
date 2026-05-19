# this is before gradle v8.11.0-M1. before commit https://github.com/gradle/gradle/commit/fabfa88bbf12b1c7258147962161fc5c2729ff6d
{
  jdk8_headless,
  jdk11_headless,
  jdk17_headless,
  jdk21_headless,
  gradle_8_11_20240905_1,
  gradle-from-source,
  mergeLock,
  jq,
  lib,
}:
gradle-from-source {
  version = "8.11-20240906-2";
  rev = "4bff127b7534bb00104c2877f865cf6f38b2e5b5";
  hash = "sha256-pBzQp1XvweP9TEBzCaCeFHKsvaK0LSmEWVrwfbLqw0g=";
  lockFile = mergeLock [
    gradle_8_11_20240905_1.unwrapped.passthru.lockFile
    # [id: 'com.gradle.develocity', version: '3.18']
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
  bootstrapGradle = gradle_8_11_20240905_1;
}
