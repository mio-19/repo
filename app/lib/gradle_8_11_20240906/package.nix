# this is before gradle v8.11.0-M1. before commit https://github.com/gradle/gradle/commit/fabfa88bbf12b1c7258147962161fc5c2729ff6d
{
  temurin-bin-8,
  temurin-bin-11,
  temurin-bin-17,
  jdk21_headless,
  gradle_8_11_20240905_2,
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
    gradle_8_11_20240905_2.unwrapped.passthru.lockFile
    # [id: 'com.gradle.develocity', version: '3.18']
    ./more.gradle.lock
  ];
  defaultJava = jdk21_headless;
  # this version specifically ask for termurin branded jdk.
  buildJdk = temurin-bin-11;
  javaToolchains = [
    temurin-bin-8
    temurin-bin-11
    temurin-bin-17
  ];
  bootstrapGradle = gradle_8_11_20240905_2;
}
