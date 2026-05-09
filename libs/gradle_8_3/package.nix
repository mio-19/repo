{
  temurin-bin-8,
  temurin-bin-11,
  temurin-bin-17,
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
  # this version specifically ask for termurin branded jdk.
  buildJdk = temurin-bin-11;
  javaToolchains = [
    temurin-bin-8
    temurin-bin-11
    temurin-bin-17
  ];
  bootstrapGradle = gradle_8_3_20230706;
}
