{
  temurin-bin-8,
  temurin-bin-11,
  temurin-bin-17,
  jdk17_headless,
  gradle-from-source,
  gradle_7_6_rc1,
  mergeLock,
}:
gradle-from-source {
  version = "7.6.0-RC4";
  hash = "sha256-3kwj/tTjVWcII+FZqIn/IsYaf22A2aeczGclGaT2asc=";
  lockFile = mergeLock [
    gradle_7_6_rc1.unwrapped.passthru.lockFile
    ./more.gradle.lock
  ];
  defaultJava = jdk17_headless;
  # this version specifically ask for termurin branded jdk.
  buildJdk = temurin-bin-11;
  javaToolchains = [
    temurin-bin-8
    temurin-bin-11
    temurin-bin-17
  ];
  bootstrapGradle = gradle_7_6_rc1;
}
