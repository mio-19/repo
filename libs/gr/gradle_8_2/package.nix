{
  jdk8_headless,
  jdk11_headless,
  jdk17_headless,
  jdk21_headless,
  gradle_8_2_bootstrap,
  gradle-from-source,
  mergeLock,
  stdenv,
  gradle-packages,
}:
if stdenv.isDarwin then
  # darwin only: Failed to extract plugin metadata from '/nix/store/q15snqpsdvdj91hjy82c10lgvspw6zc1-gradle-maven-repo/org/jetbrains/kotlin/kotlin-reflect/2.0.21/kotlin-reflect-2.0.21.jar'
  (gradle-packages.mkGradle {
    version = "8.2";
    hash = "sha256-OPZs1u7yF7TDWFW7EepOn7xTWUzMy1+4Lf0xfvjCxaM=";
    defaultJava = jdk21_headless;
  }).wrapped
else
  gradle-from-source {
    version = "8.2";
    hash = "sha256-2s5MzKtluNLcZt86AWOawI+oIBp3Sa5K68JT9OYkDZ4=";
    lockFile = mergeLock [
      gradle_8_2_bootstrap.unwrapped.passthru.lockFile
      ./more.gradle.lock
    ];
    defaultJava = jdk21_headless;
    buildJdk = jdk11_headless;
    javaToolchains = [
      jdk8_headless
      jdk11_headless
      jdk17_headless
    ];
    bootstrapGradle = gradle_8_2_bootstrap;
    gradleFlags = [
      "-PbuildKotlinVersion=1.8.20"
    ];
    postPatch = ''
      for file in \
        build-logic/jvm/src/main/kotlin/gradlebuild.unittest-and-compile.gradle.kts \
        build-logic-commons/code-quality-rules/build.gradle.kts \
        build-logic-commons/commons/build.gradle.kts \
        build-logic-commons/commons/src/main/kotlin/common.kt \
        build-logic-commons/gradle-plugin/build.gradle.kts \
        subprojects/docs/src/snippets/java/toolchain-filters/groovy/build.gradle \
        subprojects/platform-jvm/src/integTest/groovy/org/gradle/jvm/toolchain/JavaToolchainDownloadIntegrationTest.groovy
      do
        if [ -f "$file" ] && grep -Fq 'vendor = JvmVendorSpec.ADOPTIUM' "$file"; then
          substituteInPlace "$file" --replace-fail 'vendor = JvmVendorSpec.ADOPTIUM' ""
        fi
      done
    '';
  }
