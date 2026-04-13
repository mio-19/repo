{
  jdk8,
  jdk11_headless,
  jdk17_headless,
  jdk21_headless,
  gradle_8_13_M2,
  gradle-from-source,
}:
gradle-from-source {
  version = "8.13.0-M3";
  hash = "sha256-F7aHOFd2NQF6BxnMaZjqpqSjU2jGrInq0JARtWAWiSY=";
  lockFile = ./gradle.lock;
  defaultJava = jdk21_headless;
  buildJdk = jdk17_headless;
  javaToolchains = [
    "${jdk8}/lib/openjdk"
    jdk11_headless
    jdk17_headless
  ];
  # nix-shell -p javaPackages.compiler.openjdk17-bootstrap
  # nix run github:tadfisher/gradle2nix/53672d5e875235c34dee1a4c012b0269ba76e440  -- --gradle-wrapper=8.13-milestone-2
  bootstrapGradle = gradle_8_13_M2;
  postPatch = ''
    for file in \
      build-logic-settings/configuration-cache-compatibility/build.gradle.kts \
      build-logic-settings/build-environment/build.gradle.kts \
      build-logic/build-update-utils/src/main/kotlin/gradlebuild.update-versions.gradle.kts \
      build-logic/jvm/src/main/kotlin/gradlebuild.unittest-and-compile.gradle.kts \
      platforms/jvm/language-java/src/integTest/groovy/org/gradle/jvm/toolchain/JavaToolchainDownloadIntegrationTest.groovy \
      platforms/documentation/docs/src/snippets/java/toolchain-filters/kotlin/build.gradle.kts \
      platforms/documentation/docs/src/snippets/java/toolchain-filters/groovy/build.gradle \
      build-logic-commons/settings.gradle.kts \
      build-logic-commons/gradle-plugin/src/main/kotlin/gradlebuild/commons/JavaPluginExtensions.kt
    do
      if [ -f "$file" ]; then
        if grep -Fq 'vendor = JvmVendorSpec.ADOPTIUM' "$file"; then
          substituteInPlace "$file" --replace-fail 'vendor = JvmVendorSpec.ADOPTIUM' ""
        fi
        if grep -Fq 'jvmVendor = "adoptium"' "$file"; then
          substituteInPlace "$file" --replace-fail 'jvmVendor = "adoptium"' 'jvmVendor = null'
        fi
      fi
    done

    substituteInPlace gradle/gradle-daemon-jvm.properties \
      --replace-fail 'toolchainVendor=adoptium' ""
  '';
}
