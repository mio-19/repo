{
  temurin-bin-8,
  temurin-bin-11,
  temurin-bin-17,
  jdk21_headless,
  gradle_8_2_bootstrap,
  gradle-from-source,
  mergeLock,
}:
gradle-from-source {
  version = "8.2";
  hash = "sha256-2s5MzKtluNLcZt86AWOawI+oIBp3Sa5K68JT9OYkDZ4=";
  lockFile = mergeLock [
    gradle_8_2_bootstrap.unwrapped.passthru.lockFile
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
  bootstrapGradle = gradle_8_2_bootstrap;
  gradleFlags = [
    "-PbuildKotlinVersion=1.8.20"
  ];
}
