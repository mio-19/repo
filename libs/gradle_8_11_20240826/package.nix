# this is before gradle v8.11.0-M1. before commit https://github.com/gradle/gradle/commit/22b62d3e0f96288dcbd0e12bea9669848338233c
{
  temurin-bin-8,
  temurin-bin-11,
  temurin-bin-17,
  jdk21_headless,
  gradle_8_11_20240809,
  gradle-from-source,
  mergeLock,
}:
gradle-from-source {
  version = "8.11-20240826";
  rev = "4ef924c4d260b5f629e4d1641c61d60fc42e9725";
  hash = "sha256-hG7krK2lYGTLyD5PL+XN9rql7UoOX4QxcTTsTCvfA8o=";
  lockFile = mergeLock [
    gradle_8_11_20240809.unwrapped.passthru.lockFile
  ];
  defaultJava = jdk21_headless;
  # this version specifically ask for termurin branded jdk.
  buildJdk = temurin-bin-11;
  javaToolchains = [
    temurin-bin-8
    temurin-bin-11
    temurin-bin-17
  ];
  bootstrapGradle = gradle_8_11_20240809;
}
