{
  jdk8_headless,
  jdk11_headless,
  jdk17_headless,
  jdk21_headless,
  gradle_8_3_20230706,
  gradle-from-source,
  mergeLock,
}:
gradle-from-source {
  version = "8.3";
  hash = "sha256-0MORZqQX5+ZBpUKpf4RNz/57Y3fJe9++8AN35xXw6Sk=";
  lockFile = mergeLock [
    gradle_8_3_20230706.unwrapped.passthru.lockFile
    ./gradle.lock
  ];
  defaultJava = jdk21_headless;
  # gradle-from-source strips upstream Adoptium toolchain vendor requirements.
  buildJdk = jdk11_headless;
  javaToolchains = [
    jdk8_headless
    jdk11_headless
    jdk17_headless
  ];
  bootstrapGradle = gradle_8_3_20230706;
}
