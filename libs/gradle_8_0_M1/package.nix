{
  temurin-bin-8,
  temurin-bin-11,
  temurin-bin-17,
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
  ];
  defaultJava = jdk21_headless;
  # this version specifically ask for termurin branded jdk.
  buildJdk = temurin-bin-11;
  javaToolchains = [
    temurin-bin-8
    temurin-bin-11
    temurin-bin-17
  ];
  bootstrapGradle = gradle_8_0_20220911;
}
