# this is before gradle v8.11.0-M1. before commit https://github.com/gradle/gradle/commit/2b50be0d09a3f123924787e1e4117a42bac5d635
{
  jdk8_headless,
  jdk11_headless,
  jdk17_headless,
  jdk21_headless,
  gradle_8_11_20240911,
  gradle-from-source,
  mergeLock,
}:
gradle-from-source {
  version = "8.11-20240920-1";
  rev = "15ecfc89935cb8657debc4eca04df7552d41558b";
  hash = "sha256-0pjFLyxwAjfUsZk3JCOS9BAfCA848mJaQWSoqddx0j0=";
  lockFile = mergeLock [
    gradle_8_11_20240911.unwrapped.passthru.lockFile
    # org.gradle.buildtool.internal:configuration-cache-report:1.19
    ./more.gradle.lock
  ];
  defaultJava = jdk21_headless;
  buildJdk = jdk17_headless;
  javaToolchains = [
    jdk8_headless
    jdk11_headless
    jdk17_headless
  ];
  postPatch =
    let
      # grep -rl 'vendor = JvmVendorSpec.ADOPTIUM' . | sed 's/.*/"&"/'
      files = [
        "./platforms/documentation/docs/src/snippets/java/toolchain-filters/kotlin/build.gradle.kts"
        "./platforms/documentation/docs/src/snippets/java/toolchain-filters/groovy/build.gradle"
        "./platforms/jvm/language-java/src/integTest/groovy/org/gradle/jvm/toolchain/JavaToolchainDownloadIntegrationTest.groovy"
        "./build-logic-commons/gradle-plugin/src/main/kotlin/gradlebuild/commons/JavaPluginExtensions.kt"
        "./build-logic-commons/settings.gradle.kts"
        "./build-logic-settings/build-environment/build.gradle.kts"
        "./build-logic/jvm/src/main/kotlin/gradlebuild.unittest-and-compile.gradle.kts"
      ];
    in
    ''
      substituteInPlace ${builtins.concatStringsSep " " files} \
        --replace-fail 'vendor = JvmVendorSpec.ADOPTIUM' ""
    '';
  gradleFlags = [ "-Dorg.gradle.ignoreBuildJavaVersionCheck=true" ];
  bootstrapGradle = gradle_8_11_20240911;
}
