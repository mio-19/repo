# before commit https://github.com/gradle/gradle/commit/6eeed1d827d13a6918a8970ab18b4049545f1a27
{
  temurin-bin-8,
  temurin-bin-11,
  temurin-bin-17,
  jdk17_headless,
  gradle_7_6_20220514,
  gradle-from-source,
  mergeLock,
}:
gradle-from-source {
  version = "7.6.0-20220624";
  rev = "9e244e0ace2e7698374f5199570e09295950683a";
  hash = "";
  lockFile = mergeLock [
    gradle_7_6_20220514.unwrapped.passthru.lockFile
  ];
  defaultJava = jdk17_headless;
  # this version specifically ask for termurin branded jdk.
  buildJdk = temurin-bin-11;
  javaToolchains = [
    temurin-bin-8
    temurin-bin-11
    temurin-bin-17
  ];
  bootstrapGradle = gradle_7_6_20220514;
}
