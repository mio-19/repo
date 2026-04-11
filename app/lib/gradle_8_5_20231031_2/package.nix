# this is before gradle v8.5.0-RC1. before commit https://github.com/gradle/gradle/commit/dcead0376871dfd7fbd7e339ad90f0203301b75b
{
  temurin-bin-8,
  temurin-bin-11,
  temurin-bin-17,
  jdk21_headless,
  gradle_7_6,
  gradle-from-source,
}:
gradle-from-source {
  version = "8.5.0-20231031-2";
  rev = "86eae75ebdaf9ada4e777639c3810a42d3065cdc";
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
  bootstrapGradle = gradle_7_6;
}
