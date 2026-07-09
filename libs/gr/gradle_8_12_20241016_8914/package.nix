# this is before gradle_12_rc1. before commit https://github.com/gradle/gradle/commit/8fedfda9beb743506987e60df2e08c31017beb87
{
  jdk17_headless,
  jdk21_headless,
  gradle_8_12_20241015,
  gradle-from-source,
  mergeLock,
}:
gradle-from-source {
  version = "8.12-20241016-8914";
  rev = "8914d57e1d5a618f624aff602d54947dcf224350";
  hash = "sha256-8GKrGKyJQ11qrZEXbQNPmhYL2KiZuoSJwfHPwfcUaOE=";
  lockFile = mergeLock [
    ../gradle_8_12_20241015/gradle.lock
    ../gradle_8_12_1/gradle.lock
  ];
  defaultJava = jdk21_headless;
  buildJdk = jdk17_headless;
  # nix-shell -p javaPackages.compiler.openjdk17-bootstrap
  # nix run github:tadfisher/gradle2nix/v2  -- --gradle-home=/nix/store/2fqkjv8xnwcf495q2xnj112vh84ar01v-gradle-8.12-20241015/libexec/gradle
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
