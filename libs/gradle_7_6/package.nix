{
  jdk8_headless,
  jdk11_headless,
  jdk17_headless,
  gradle-from-source,
  gradle_7_6_rc4,
  mergeLock,
}:
gradle-from-source {
  version = "7.6.0";
  hash = "sha256-RWEALk7H51a3ztnA6UFJVLjQIthfpruP1e22TD/LnR8=";
  lockFile = mergeLock [
    gradle_7_6_rc4.unwrapped.passthru.lockFile
  ];
  defaultJava = jdk17_headless;
  # gradle-from-source strips upstream Adoptium toolchain vendor requirements.
  buildJdk = jdk11_headless;
  javaToolchains = [
    jdk8_headless
    jdk11_headless
    jdk17_headless
  ];
  bootstrapGradle = gradle_7_6_rc4;
}
