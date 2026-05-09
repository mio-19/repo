# this is before gradle v8.11.0-M1. before commit https://github.com/gradle/gradle/commit/370ef936bf8edd86bc881ad1f54229c164f2e67f
{
  jdk8_headless,
  jdk11_headless,
  jdk17_headless,
  jdk21_headless,
  gradle_8_11_20240807,
  gradle-from-source,
  runCommand,
  jq,
  lib,
  mergeLock,
}:
gradle-from-source {
  version = "8.11-20240808-1";
  rev = "e69fb10f926324a9f861515ddf0c80419b24b899";
  hash = "sha256-FBK/ROz5YmETf4M+vEVYrBxJiDo08lTW3bp3h4WgN3g=";
  # org.jetbrains.kotlinx:kotlinx-metadata-jvm:0.7.0 org.jetbrains.kotlinx:kotlinx-metadata-jvm:0.7.0 org.jetbrains.kotlin:kotlin-scripting-compiler-impl-embeddable:2.0.0 org.gradle.buildtool.internal:configuration-cache-report:1.11
  lockFile = mergeLock [
    gradle_8_11_20240807.unwrapped.passthru.lockFile
    ./more.gradle.lock
  ];
  defaultJava = jdk21_headless;
  # gradle-from-source strips upstream Adoptium toolchain vendor requirements.
  buildJdk = jdk11_headless;
  javaToolchains = [
    jdk8_headless
    jdk11_headless
    jdk17_headless
  ];
  bootstrapGradle = gradle_8_11_20240807;
}
