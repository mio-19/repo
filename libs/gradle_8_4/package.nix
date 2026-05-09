{
  jdk8_headless,
  jdk11_headless,
  jdk17_headless,
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
  # gradle-from-source strips upstream Adoptium toolchain vendor requirements.
  buildJdk = jdk11_headless;
  javaToolchains = [
    jdk8_headless
    jdk11_headless
    jdk17_headless
  ];
  gradleFlags = [
    "-PbuildKotlinVersion=1.9.10"
  ];
  bootstrapGradle = gradle_8_3;
}
