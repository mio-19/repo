# before https://github.com/gradle/gradle/commit/eca8b9d5547c5df01af4ca4a3f483e2b7c8b28e7
{
  temurin-bin-8,
  temurin-bin-11,
  temurin-bin-17,
  jdk21_headless,
  gradle_8_7_20240118_1,
  gradle-from-source,
  mergeLock,
}:
gradle-from-source {
  version = "8.7.0-20240118-2";
  rev = "318fea30a18b28b341841954977367da6c415cae";
  hash = "sha256-bK0dU0VuX+5JzjYQ8qjK0Paz4No037bhnLBqppo1/Jc=";
  lockFile = mergeLock [
    gradle_8_7_20240118_1.unwrapped.passthru.lockFile
    ../gradle_8_7_rc1/gradle.lock
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
  bootstrapGradle = gradle_8_7_20240118_1;
}
