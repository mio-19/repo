{
  temurin-bin-8,
  temurin-bin-11,
  temurin-bin-17,
  jdk21_headless,
  gradle_8_3,
  gradle-from-source,
  mergeLock,
}:
gradle-from-source {
  version = "8.4";
  hash = "sha256-RPDvx2Whyg5yY8aHmdjMAghpBe497/F4QOxUopqh97k=";
  lockFile = mergeLock [
    gradle_8_3.unwrapped.passthru.lockFile
    ./gradle.lock
  ];
  patches = [
    ./disable-dependency-verification.patch
  ];
  defaultJava = jdk21_headless;
  # this version specifically ask for termurin branded jdk.
  buildJdk = temurin-bin-11;
  javaToolchains = [
    temurin-bin-8
    temurin-bin-11
    temurin-bin-17
  ];
  gradleFlags = [
    "-PbuildKotlinVersion=1.9.10"
  ];
  bootstrapGradle = gradle_8_3;
}
