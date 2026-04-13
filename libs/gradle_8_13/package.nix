{
  temurin-bin-8,
  temurin-bin-11,
  temurin-bin-17,
  jdk21_headless,
  gradle_8_13_rc1,
  gradle-from-source,
  gradle-packages,
  stdenv,
}:
if stdenv.isDarwin then
  # no termurin-bin-* on darwin
  (gradle-packages.mkGradle {
    version = "8.13";
    hash = "sha256-IPGxF2I3JUpvwgTYQ0GW+hGkz7OHVnUZxhVW6HEK7Xg=";
    defaultJava = jdk21_headless;
  }).wrapped
else
  gradle-from-source {
    version = "8.13";
    hash = "sha256-VhV58GDtZRjlQFtG1knTbm7vJP2JrrSr5yD/3/+yTnM=";
    lockFile = ./gradle.lock;
    defaultJava = jdk21_headless;
    # this version specifically ask for termurin branded jdk.
    buildJdk = temurin-bin-17;
    javaToolchains = [
      temurin-bin-8
      temurin-bin-11
      temurin-bin-17
    ];
    # nix-shell -p javaPackages.compiler.openjdk17-bootstrap
    # nix run github:tadfisher/gradle2nix/53672d5e875235c34dee1a4c012b0269ba76e440  -- --gradle-wrapper=8.13-rc-1
    bootstrapGradle = gradle_8_13_rc1;
    postPatch =
      let
        # grep -rl 'vendor = JvmVendorSpec.ADOPTIUM' . | sed 's/.*/"&"/'
        files = [
          "./build-logic-settings/configuration-cache-compatibility/build.gradle.kts"
          "./build-logic-settings/build-environment/build.gradle.kts"
          "./build-logic/build-update-utils/src/main/kotlin/gradlebuild.update-versions.gradle.kts"
          "./build-logic/jvm/src/main/kotlin/gradlebuild.unittest-and-compile.gradle.kts"
          "./platforms/jvm/language-java/src/integTest/groovy/org/gradle/jvm/toolchain/JavaToolchainDownloadIntegrationTest.groovy"
          "./platforms/documentation/docs/src/snippets/java/toolchain-filters/kotlin/build.gradle.kts"
          "./platforms/documentation/docs/src/snippets/java/toolchain-filters/groovy/build.gradle"
          "./build-logic-commons/settings.gradle.kts"
          "./build-logic-commons/gradle-plugin/src/main/kotlin/gradlebuild/commons/JavaPluginExtensions.kt"
        ];
      in
      ''
        substituteInPlace ${builtins.concatStringsSep " " files} \
          --replace-fail 'vendor = JvmVendorSpec.ADOPTIUM' ""
      '';
  }
