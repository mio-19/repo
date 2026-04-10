{
  temurin-bin-8,
  temurin-bin-11,
  temurin-bin-17,
  jdk21_headless,
  gradle_8_11_20240920_2,
  gradle-from-source,
  mergeLock,
}:
gradle-from-source {
  version = "8.11.0-M1";
  hash = "sha256-+0ijcrkUCFa1JTNM0rEEXgYuz0sZfHBdR4eWl5H2iDg=";
  lockFile = mergeLock [
    gradle_8_11_20240920_2.unwrapped.passthru.lockFile
    # org.gradle.buildtool.internal:configuration-cache-report:1.21
    ../gradle_8_12_20241015/gradle.lock
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
  bootstrapGradle = gradle_8_11_20240920_2;
}
