{
  jdk8_headless,
  jdk11_headless,
  jdk17_headless,
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
  # gradle-from-source strips upstream Adoptium toolchain vendor requirements.
  buildJdk = jdk11_headless;
  javaToolchains = [
    jdk8_headless
    jdk11_headless
    jdk17_headless
  ];
  bootstrapGradle = gradle_8_2_bootstrap;
  gradleFlags = [
    "-PbuildKotlinVersion=1.8.20"
  ];
}
