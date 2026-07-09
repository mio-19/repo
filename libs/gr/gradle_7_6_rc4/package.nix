{
  jdk8_headless,
  jdk11_headless,
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
  # this version specifically ask for Temurin branded jdk.
  relaxJavaVendor = true;
  buildJdk = jdk11_headless;
  javaToolchains = [
    jdk8_headless
    jdk11_headless
    jdk17_headless
  ];
  bootstrapGradle = gradle_7_6_rc1;
}
