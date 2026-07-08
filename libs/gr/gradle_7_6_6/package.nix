{
  jdk8_headless,
  jdk11_headless,
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
  # this version specifically ask for Temurin branded jdk.
  relaxJavaVendor = true;
  buildJdk = jdk11_headless;
  javaToolchains = [
    jdk8_headless
    jdk11_headless
    jdk17_headless
  ];
  bootstrapGradle = gradle_7_6;
}
