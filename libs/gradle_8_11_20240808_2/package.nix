# this is before gradle v8.11.0-M1. before commit https://github.com/gradle/gradle/commit/ae4c9bac254511e9e94c22b473fa0b746d6d2b4a
{
  jdk8_headless,
  jdk11_headless,
  jdk17_headless,
  jdk21_headless,
  gradle_8_11_20240808_1,
  gradle-from-source,
  runCommand,
  mergeLock,
  lib,
}:
gradle-from-source {
  version = "8.11-20240808-2";
  rev = "c2454dd71782f1affb28858269f1360e96763033";
  hash = "sha256-tfMknJmlZ70ZtMgLf8J54nCSxuHz1fpgygiijsjJhh8=";
  # org.gradle.kotlin.kotlin-dsl:org.gradle.kotlin.kotlin-dsl.gradle.plugin:5.0.0 org.jetbrains.kotlin:kotlin-stdlib:2.0.10
  lockFile = mergeLock [
    gradle_8_11_20240808_1.unwrapped.passthru.lockFile
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
  bootstrapGradle = gradle_8_11_20240808_1;
}
