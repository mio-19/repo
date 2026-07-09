# this is before gradle_12_rc1. before commit https://github.com/gradle/gradle/commit/864ddaf0a289b122e804046ab4a0e618dce9b8e7
{
  jdk8_headless,
  jdk11_headless,
  jdk17_headless,
  jdk21_headless,
  gradle_8_11_20240920_1,
  gradle-from-source,
  gradle-packages,
  stdenv,
}:
if stdenv.isDarwin then
  # no termurin-bin-* on darwin
  (gradle-packages.mkGradle {
    version = "8.11.1";
    hash = "sha256-85eyhwI6zboen2/F6nLSLdY2adWe1KKJopsadu7hUcY=";
    defaultJava = jdk21_headless;
  }).wrapped
else
  gradle-from-source {
    version = "8.11.1";
    hash = "sha256-s9Fcf6zz0TTLEFeq0zGxovCppZGluIV3ux8XmcDdF2A=";
    lockFile = ./gradle.lock;
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
        build-logic-commons/gradle-plugin/src/main/kotlin/gradlebuild/commons/JavaPluginExtensions.kt \
        build-logic-commons/settings.gradle.kts \
        platforms/documentation/docs/src/snippets/java/toolchain-filters/groovy/build.gradle \
        platforms/documentation/docs/src/snippets/java/toolchain-filters/kotlin/build.gradle.kts \
        platforms/jvm/language-java/src/integTest/groovy/org/gradle/jvm/toolchain/JavaToolchainDownloadIntegrationTest.groovy
      do
        if [ -f "$file" ] && grep -Fq 'vendor = JvmVendorSpec.ADOPTIUM' "$file"; then
          substituteInPlace "$file" --replace-fail 'vendor = JvmVendorSpec.ADOPTIUM' ""
        fi
      done
    '';
    # nix-shell -p javaPackages.compiler.openjdk11-bootstrap
    # nix run github:tadfisher/gradle2nix/v2  -- --gradle-wrapper=8.11-milestone-1
    # bootstrap chain skip; standalone build still uses gradle_8_11_M1
    bootstrapGradle = gradle_8_11_20240920_1;
  }
