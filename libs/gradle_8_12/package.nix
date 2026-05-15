{
  jdk8_headless,
  jdk11_headless,
  jdk17_headless,
  jdk21_headless,
  gradle_8_12_rc1,
  gradle-from-source,
  mergeLock,
  gradle-packages,
  stdenv,
}:
if stdenv.isDarwin then
  # no termurin-bin-* on darwin
  (gradle-packages.mkGradle {
    version = "8.12";
    hash = "sha256-egDVH7kxR4Gaq3YCT+7OILa4TkIGlBAfJ2vpUuCL7wM=";
    defaultJava = jdk21_headless;
  }).wrapped
else
  gradle-from-source {
    version = "8.12";
    hash = "sha256-L20ZLLXJYb5HsEWJF1EB5NPsWOIimH1JQtd/yRPWO/s=";
    lockFile = mergeLock [
      gradle_8_12_rc1.unwrapped.passthru.lockFile
      ../gradle_8_12_1/gradle.lock
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

        substituteInPlace gradle/gradle-daemon-jvm.properties \
          --replace-fail 'toolchainVendor=adoptium' ""
      '';
    # nix-shell -p javaPackages.compiler.openjdk17-bootstrap
    # nix run github:tadfisher/gradle2nix/53672d5e875235c34dee1a4c012b0269ba76e440  -- --gradle-wrapper=8.12-rc-1
    bootstrapGradle = gradle_8_12_rc1;
  }
