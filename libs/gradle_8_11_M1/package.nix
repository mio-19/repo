{
  jdk8_headless,
  jdk11_headless,
  jdk17_headless,
  jdk21_headless,
  gradle_8_11_20240920_1,
  gradle-from-source,
  mergeLock,
}:
gradle-from-source {
  version = "8.11.0-M1";
  hash = "sha256-+0ijcrkUCFa1JTNM0rEEXgYuz0sZfHBdR4eWl5H2iDg=";
  lockFile = mergeLock [
    gradle_8_11_20240920_1.unwrapped.passthru.lockFile
    # org.gradle.buildtool.internal:configuration-cache-report:1.21
    ../gradle_8_12_20241015/gradle.lock
  ];
  defaultJava = jdk21_headless;
  # gradle-from-source strips upstream Adoptium toolchain vendor requirements.
  buildJdk = jdk11_headless;
  javaToolchains = [
    jdk8_headless
    jdk11_headless
    jdk17_headless
  ];
  bootstrapGradle = gradle_8_11_20240920_1;
}
