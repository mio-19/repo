# this is before gradle_12_rc1. https://github.com/gradle/gradle/commit/864ddaf0a289b122e804046ab4a0e618dce9b8e7
{
  jdk17_headless,
  jdk21_headless,
  gradle_8_12_20241015,
  gradle-from-source,
  mergeLock,
}:
gradle-from-source {
  version = "8.12-20241016-864d";
  rev = "864ddaf0a289b122e804046ab4a0e618dce9b8e7";
  hash = "sha256-BPB0LHdA5eMegwHRFfvPTgoFEwTMSLvU1xtxkYriVcY=";
  lockFile = mergeLock [
    ../gradle_8_12_20241015/gradle.lock
    ../gradle_8_12_1/gradle.lock
  ];
  defaultJava = jdk21_headless;
  buildJdk = jdk17_headless;
  bootstrapGradle = gradle_8_12_20241015;
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

      substituteInPlace gradle/gradle-daemon-jvm.properties \
        --replace-fail 'toolchainVendor=adoptium' ""
    '';
}
