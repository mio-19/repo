{
  temurin-bin-8,
  temurin-bin-11,
  temurin-bin-17,
  jdk21_headless,
  gradle_8_0,
  gradle-from-source,
  mergeLock,
}:
gradle-from-source {
  version = "8.1-20230201";
  rev = "49e26e21af444eb1e07e240a1cfed0c7ddbbc235";
  hash = "sha256-QKD1U/Jnkh067GWfB/DoBJNXLI6KQvBmEvM/0NDH8iA=";
  lockFile = mergeLock [
    gradle_8_0.unwrapped.passthru.lockFile
    ./gradle.lock
    ../gradle_8_1/more.gradle.lock
  ];
  defaultJava = jdk21_headless;
  buildJdk = temurin-bin-11;
  javaToolchains = [
    temurin-bin-8
    temurin-bin-11
    temurin-bin-17
  ];
  bootstrapGradle = gradle_8_0;
  postPatch = ''
    substituteInPlace \
      build-logic/jvm/src/main/kotlin/gradlebuild.unittest-and-compile.gradle.kts \
      build-logic-commons/code-quality-rules/build.gradle.kts \
      build-logic-commons/commons/build.gradle.kts \
      build-logic-commons/commons/src/main/kotlin/common.kt \
      build-logic-commons/gradle-plugin/build.gradle.kts \
      --replace-fail 'languageVersion = JavaLanguageVersion.of(11)' 'languageVersion.set(JavaLanguageVersion.of(11))' \
      --replace-fail 'vendor = JvmVendorSpec.ADOPTIUM' 'vendor.set(JvmVendorSpec.ADOPTIUM)'
  '';
}
