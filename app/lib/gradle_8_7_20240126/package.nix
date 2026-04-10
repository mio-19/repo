# before https://github.com/gradle/gradle/commit/edde41dec57b90b08d3172130eb71a991f61464c
{
  temurin-bin-8,
  temurin-bin-11,
  temurin-bin-17,
  jdk21_headless,
  gradle_8_7_20240118_3,
  gradle-from-source,
}:
gradle-from-source {
  version = "8.7.0-20240126";
  rev = "6b5635d02c7fb6a663797dcbd3f40e779b8fc989";
  hash = "";
  lockFile = ./gradle.lock;
  defaultJava = jdk21_headless;
  # this version specifically ask for termurin branded jdk.
  buildJdk = temurin-bin-11;
  javaToolchains = [
    temurin-bin-8
    temurin-bin-11
    temurin-bin-17
  ];
  bootstrapGradle = gradle_8_7_20240118_3;
}
