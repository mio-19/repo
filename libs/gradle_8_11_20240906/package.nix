# this is before gradle v8.11.0-M1. before commit https://github.com/gradle/gradle/commit/fabfa88bbf12b1c7258147962161fc5c2729ff6d
{
  jdk8_headless,
  jdk11_headless,
  jdk17_headless,
  jdk21_headless,
  gradle_8_11_20240905_1,
  gradle-from-source,
  mergeLock,
  jq,
  lib,
}:
gradle-from-source {
  version = "8.11-20240906-2";
  rev = "4bff127b7534bb00104c2877f865cf6f38b2e5b5";
  hash = "sha256-pBzQp1XvweP9TEBzCaCeFHKsvaK0LSmEWVrwfbLqw0g=";
  lockFile = mergeLock [
    gradle_8_11_20240905_1.unwrapped.passthru.lockFile
    # [id: 'com.gradle.develocity', version: '3.18']
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
  bootstrapGradle = gradle_8_11_20240905_1;
}
