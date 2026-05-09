# before https://github.com/gradle/gradle/commit/edde41dec57b90b08d3172130eb71a991f61464c
{
  jdk8_headless,
  jdk11_headless,
  jdk17_headless,
  jdk21_headless,
  gradle_8_7_20240118_3,
  gradle-from-source,
  mergeLock,
}:
gradle-from-source {
  version = "8.7.0-20240126";
  rev = "6b5635d02c7fb6a663797dcbd3f40e779b8fc989";
  hash = "sha256-OBRUIBqp2eJRJrySttyO53vn20S/ZMqsyZ1zMkm07MA=";
  lockFile = mergeLock [
    gradle_8_7_20240118_3.unwrapped.passthru.lockFile
  ];
  defaultJava = jdk21_headless;
  # gradle-from-source strips upstream Adoptium toolchain vendor requirements.
  buildJdk = jdk11_headless;
  javaToolchains = [
    jdk8_headless
    jdk11_headless
    jdk17_headless
  ];
  bootstrapGradle = gradle_8_7_20240118_3;
}
