# this is before gradle v8.11.0-M1. before commit https://github.com/gradle/gradle/commit/ea3f2b4ff4b17341830905cad9c7fa1b2db7f03b
{
  jdk8_headless,
  jdk11_headless,
  jdk17_headless,
  jdk21_headless,
  gradle_8_11_20240808_2,
  gradle_8_11_20240809,
  gradle-from-source,
  mergeLock,
}:
gradle-from-source {
  version = "8.11-20240903";
  rev = "72bdc3250c2efab2d5113f47f49d4139ccd18ee5";
  hash = "sha256-G2kipnZ2F13xKPnpB8MtNA9qWFV818KUMgvgN3AUQG8=";
  lockFile = mergeLock [
    gradle_8_11_20240809.unwrapped.passthru.lockFile
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
  # bootstrap chain skip; standalone build still uses gradle_8_11_20240809
  bootstrapGradle = gradle_8_11_20240808_2;
}
