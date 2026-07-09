{
  jdk8_headless,
  jdk11_headless,
  jdk17_headless,
  jdk21_headless,
  gradle_8_0_20220911,
  gradle-from-source,
  mergeLock,
}:
gradle-from-source {
  version = "8.0.0-M1";
  hash = "sha256-UryEnkFxVTtnUf2b4So6EzGO2SJzqYlrREe1TycytAE=";
  lockFile = mergeLock [
    gradle_8_0_20220911.unwrapped.passthru.lockFile
    ./more.gradle.lock
  ];
  defaultJava = jdk21_headless;
  # this version specifically ask for Temurin branded jdk.
  relaxJavaVendor = true;
  buildJdk = jdk11_headless;
  javaToolchains = [
    jdk8_headless
    jdk11_headless
    jdk17_headless
  ];
  bootstrapGradle = gradle_8_0_20220911;
}
