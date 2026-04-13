# this is before gradle v8.5.0-RC1. before commit https://github.com/gradle/gradle/commit/584f31a86e0a1ba4ab5b1a1a4de896f03d2ddbb1
{
  temurin-bin-8,
  temurin-bin-11,
  temurin-bin-17,
  jdk21_headless,
  gradle_7_6,
  gradle-from-source,
}:
gradle-from-source {
  version = "8.5.0-20231101-1";
  rev = "1c57b7f62eba4d5ef8d8da898eadf5299bf3e330";
  hash = "";
  lockFile = { };
  defaultJava = jdk21_headless;
  # this version specifically ask for termurin branded jdk.
  buildJdk = temurin-bin-11;
  javaToolchains = [
    temurin-bin-8
    temurin-bin-11
    temurin-bin-17
  ];
  bootstrapGradle = gradle_7_6;
}
