{
  jdk8_headless,
  jdk11_headless,
  jdk17_headless,
  gradle-from-source,
  gradle_7_6_M1,
  mergeLock,
}:
gradle-from-source {
  version = "7.6.0-RC1";
  hash = "sha256-CWHRq84wSXUiPkKOHnRLyFdAH7GME1kw4cA5WbQgolE=";
  lockFile = mergeLock [
    gradle_7_6_M1.unwrapped.passthru.lockFile
    ./more.gradle.lock
  ];
  defaultJava = jdk17_headless;
  # gradle-from-source strips upstream Adoptium toolchain vendor requirements.
  buildJdk = jdk11_headless;
  javaToolchains = [
    jdk8_headless
    jdk11_headless
    jdk17_headless
  ];
  bootstrapGradle = gradle_7_6_M1;
}
