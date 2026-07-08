{
  jdk8_headless,
  jdk11_headless,
  jdk17_headless,
  jdk21_headless,
  gradle_8_5_rc1,
  gradle-from-source,
  gradle-packages,
  stdenv,
}:
if stdenv.isDarwin then
  # no termurin-bin-* on darwin
  (gradle-packages.mkGradle {
    version = "8.6-rc-2";
    hash = "sha256-OjbO3SXAIzXZkeNoTheYUjkVDiS3RKhRPUZlQwg8olA=";
    defaultJava = jdk21_headless;
  }).wrapped
else
  gradle-from-source {
    version = "8.6.0-RC2";
    hash = "sha256-cvOfz+HoG4rSjbeG8rPQXE7sRBIMog5/Q3K7juhLnHw=";
    lockFile = ./gradle.lock;
    defaultJava = jdk21_headless;
    buildJdk = jdk11_headless;
    javaToolchains = [
      jdk8_headless
      jdk11_headless
      jdk17_headless
    ];
    # nix-shell -p javaPackages.compiler.openjdk11-bootstrap
    # nix run github:tadfisher/gradle2nix/v2  -- --gradle-wrapper=8.5-rc-1
    bootstrapGradle = gradle_8_5_rc1;
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
