{
  jdk8_headless,
  jdk11_headless,
  jdk17_headless,
  jdk21_headless,
  gradle_8_10_rc1,
  gradle-from-source,
  mergeLock,
  stdenv,
  gradle-packages,
}:
if stdenv.isDarwin then
  # darwin only: Internal compiler error. See log for more details
  (gradle-packages.mkGradle {
    version = "8.10.2";
    hash = "";
    defaultJava = jdk21_headless;
  }).wrapped
else
  gradle-from-source {
    version = "8.10.2";
    hash = "sha256-KwpfhYAjroe7AnRjztyn00fXCxYYK0hXnTpWS7Hreaw=";
    lockFile = mergeLock [
      gradle_8_10_rc1.unwrapped.passthru.lockFile
      ../gradle_8_10/gradle.lock
      ../gradle_8_11_20240807/gradle.lock
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
    # nix-shell -p javaPackages.compiler.openjdk11-bootstrap
    # nix run github:tadfisher/gradle2nix/v2  -- --gradle-wrapper=8.10-rc-1
    bootstrapGradle = gradle_8_10_rc1;
    configureOnDemand = true;
  }
