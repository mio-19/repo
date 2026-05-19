{
  temurin-bin-8,
  temurin-bin-11,
  temurin-bin-17,
  jdk17_headless,
  gradle-from-source,
  gradle_7_6,
  mergeLock,
}:
gradle-from-source {
  version = "7.6.6";
  hash = "sha256-dz7U2Uc9mIN5koHqRZTJtfcw6EFjdtLEnwXELyGLHLM=";
  lockFile = mergeLock [
    gradle_7_6.unwrapped.passthru.lockFile
    ../gradle_8_10/gradle.lock
    ../gradle_8_14_4/gradle.lock
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
  bootstrapGradle = gradle_7_6;
}
