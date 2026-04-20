# this is before gradle_12_rc1. before commit https://github.com/gradle/gradle/commit/06e9ee64049155fcdddd08010a0f10bbed19c60a
{
  jdk17_headless,
  jdk21_headless,
  gradle_8_12_20241016_8914,
  gradle-from-source,
}:
gradle-from-source {
  version = "8.12-20241126";
  rev = "6a764a9cc3c07120fb418357adab84d8b1c1fe91";
  hash = "sha256-h0B76hX0FBSYXwbwlCjpXqkFFbJ51iPROgkaiQgXbZY=";
  lockFile = ./gradle.lock;
  defaultJava = jdk21_headless;
  buildJdk = jdk17_headless;
  # nix-shell -p javaPackages.compiler.openjdk17-bootstrap
  # nix run github:tadfisher/gradle2nix/v2  -- --gradle-home=/nix/store/p0k528kprsib13134wk5wdv4gg14i0z0-gradle-8.12-20241016-8914/libexec/gradle
  bootstrapGradle = gradle_8_12_20241016_8914;
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
