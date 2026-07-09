{
  jdk8_headless,
  jdk11_headless,
  jdk17_headless,
  jdk21_headless,
  gradle-from-source,
  gradle_8_9_20240529,
  mergeLock,
  jq,
  lib,
}:
gradle-from-source {
  version = "8.9.0-RC1";
  hash = "sha256-VnYpNXi/ztBSZiwdaWzRWajxZL1rHAXENvoE2ZHi+Yk=";
  # nix-shell -p javaPackages.compiler.openjdk11-bootstrap
  # nix run github:tadfisher/gradle2nix/v2  -- --gradle-wrapper=8.9-rc-1
  # why generate lock file with different version? beacuse it is easier. it doesn't match bootstrapGradle.
  lockFile = mergeLock [
    gradle_8_9_20240529.unwrapped.passthru.lockFile
    ./gradle.lock
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
  bootstrapGradle = gradle_8_9_20240529;
}
