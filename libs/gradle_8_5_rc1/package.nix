{
  jdk8_headless,
  jdk11_headless,
  jdk17_headless,
  jdk21_headless,
  gradle_8_4,
  gradle-from-source,
  mergeLock,
}:
gradle-from-source {
  version = "8.5.0-RC1";
  hash = "sha256-UGzP4x2FaeMvh7XdT6zT2m4/fJJqd9LsP7Fo/+kVfK4=";
  lockFile = mergeLock [
    gradle_8_4.unwrapped.passthru.lockFile
    ./gradle.lock
  ];
  patches = [
    ./disable-dependency-verification.patch
  ];
  defaultJava = jdk21_headless;
  buildJdk = jdk11_headless;
  javaToolchains = [
    jdk8_headless
    jdk11_headless
    jdk17_headless
  ];
  gradleFlags = [
    "-PbuildKotlinVersion=1.9.20"
  ];
  bootstrapGradle = gradle_8_4;
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
      platforms/jvm/language-java/src/integTest/groovy/org/gradle/jvm/toolchain/JavaToolchainDownloadIntegrationTest.groovy \
      subprojects/docs/src/snippets/java/toolchain-filters/groovy/build.gradle \
      subprojects/docs/src/snippets/java/toolchain-filters/kotlin/build.gradle.kts
    do
      if [ -f "$file" ] && grep -Fq 'vendor = JvmVendorSpec.ADOPTIUM' "$file"; then
        substituteInPlace "$file" --replace-fail 'vendor = JvmVendorSpec.ADOPTIUM' ""
      fi
    done
  '';
}
