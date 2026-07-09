# before https://github.com/gradle/gradle/commit/1ac201fb971f512686fd56ad2560f7ca5cf6771b
{
  jdk8_headless,
  jdk11_headless,
  jdk17_headless,
  jdk21_headless,
  gradle_8_8,
  gradle-from-source,
}:
gradle-from-source {
  version = "8.9.0-20240411";
  rev = "5198078ea54d85e33bfd6a1859762353530e1997";
  hash = "sha256-CxdSGHZaJN8tZgNsjb6Uufpx+cEgZd8DZ4ZpnSdBePA=";
  lockFile = ./gradle.lock;
  defaultJava = jdk21_headless;
  buildJdk = jdk11_headless;
  javaToolchains = [
    jdk8_headless
    jdk11_headless
    jdk17_headless
  ];
  # nix-shell -p javaPackages.compiler.openjdk11-bootstrap
  # nix run github:tadfisher/gradle2nix/v2  -- --gradle-wrapper=8.8
  bootstrapGradle = gradle_8_8;
  configureOnDemand = true;
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
}
