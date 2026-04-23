{
  temurin-bin-8,
  temurin-bin-11,
  temurin-bin-17,
  jdk21_headless,
  gradle_8_0_M2,
  gradle_8_0_20220911,
  gradle-from-source,
  mergeLock,
  lib,
}:
gradle-from-source {
  version = "8.0.0-M3";
  tag = "v8.0.0-M3";
  hash = "sha256-K+WBCrC1enk6LM2rN6lX2hIhH0bGGMNbr6/hqq1JMDM=";
  lockFile = mergeLock [
    gradle_8_0_M2.unwrapped.passthru.lockFile
    gradle_8_0_20220911.unwrapped.passthru.lockFile
    ../gradle_8_0/more.gradle.lock
    ../gradle_7_6_rc1/more.gradle.lock
  ];
  defaultJava = jdk21_headless;
  # this version specifically ask for termurin branded jdk.
  buildJdk = temurin-bin-11;
  javaToolchains = [
    temurin-bin-8
    temurin-bin-11
    temurin-bin-17
  ];
  bootstrapGradle = gradle_8_0_M2;
}
