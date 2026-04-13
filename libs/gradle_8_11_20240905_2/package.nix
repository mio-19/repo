# this is before gradle v8.11.0-M1. before commit https://github.com/gradle/gradle/commit/4391d3b3320b6fdea92f62fbd002669237918236
{
  temurin-bin-8,
  temurin-bin-11,
  temurin-bin-17,
  jdk21_headless,
  gradle_8_11_20240905_1,
  gradle-from-source,
  mergeLock,
}:
gradle-from-source {
  version = "8.11-20240905-2";
  rev = "b778a156ecd6aaa6dd2879b6e067b529ce5b2555";
  hash = "sha256-s8NxXPlUkVNRIlHExcUNKF+GHHend9w3g6qEQmPUmDE=";
  lockFile = mergeLock [
    gradle_8_11_20240905_1.unwrapped.passthru.lockFile
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
  bootstrapGradle = gradle_8_11_20240905_1;
}
