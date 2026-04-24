{
  jdk17_headless,
  jdk21_headless,
  gradle_8_12_20241015,
  gradle-from-source,
  mergeLock,
}:
gradle-from-source {
  version = "8.12.0-RC1";
  hash = "sha256-AfBP4nX8M//8WVCkN48MG6Rl5XoYwARIadmpYM/O07U=";
  lockFile = mergeLock [
    ../gradle_8_12_20241126/gradle.lock
    ../gradle_8_12_1/gradle.lock
  ];
  defaultJava = jdk21_headless;
  buildJdk = jdk17_headless;
  # nix-shell -p javaPackages.compiler.openjdk17-bootstrap
  # nix run github:tadfisher/gradle2nix/effc6f3c8ba22e718eb4fb31f09219d0fcc75649  -- --gradle-home=/nix/store/2fqkjv8xnwcf495q2xnj112vh84ar01v-gradle-8.12-20241015/libexec/gradle
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
