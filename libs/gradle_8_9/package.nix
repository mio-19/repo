{
  jdk8_headless,
  jdk11_headless,
  jdk17_headless,
  jdk21_headless,
  gradle_8_9_20240529,
  gradle_8_9_rc2,
  gradle-from-source,
  mergeLock,
  stdenv,
  gradle-packages,
}:
if stdenv.isDarwin then
  (gradle-packages.mkGradle {
    version = "8.9";
    hash = "sha256-1yXXB7+r1N/clYxiQAOzyArMwD9wN7USLEsdDvFc7Ks=";
    defaultJava = jdk21_headless;
  }).wrapped
else
  gradle-from-source {
    version = "8.9";
    hash = "sha256-+Txu5sYJ3mY27aBIW2L48jcR3DdDozfGpQX0nUyHBlo=";
    lockFile = mergeLock [
      gradle_8_9_rc2.unwrapped.passthru.lockFile
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
    # bootstrap chain skip; standalone build still uses gradle_8_9_rc2
    bootstrapGradle = gradle_8_9_20240529;
    # nix run github:tadfisher/gradle2nix/v2 -- --gradle-wrapper=8.9-rc-2
  }
