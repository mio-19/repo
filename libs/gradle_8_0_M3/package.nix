{
  jdk8_headless,
  jdk11_headless,
  jdk17_headless,
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
  # gradle-from-source strips upstream Adoptium toolchain vendor requirements.
  buildJdk = jdk11_headless;
  javaToolchains = [
    jdk8_headless
    jdk11_headless
    jdk17_headless
  ];
  bootstrapGradle = gradle_8_0_M2;
}
