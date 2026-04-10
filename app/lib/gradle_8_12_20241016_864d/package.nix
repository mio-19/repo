# this is before gradle_12_rc1. https://github.com/gradle/gradle/commit/864ddaf0a289b122e804046ab4a0e618dce9b8e7
{
  temurin-bin-8,
  temurin-bin-11,
  temurin-bin-17,
  jdk21_headless,
  gradle_8_12_20241015,
  gradle-from-source,
}:
gradle-from-source {
  version = "8.12-20241016-864d";
  rev = "864ddaf0a289b122e804046ab4a0e618dce9b8e7";
  hash = "sha256-BPB0LHdA5eMegwHRFfvPTgoFEwTMSLvU1xtxkYriVcY=";
  lockFile = ./gradle.lock;
  defaultJava = jdk21_headless;
  # this version specifically ask for termurin branded jdk.
  buildJdk = temurin-bin-17;
  javaToolchains = [
    temurin-bin-8
    temurin-bin-11
    temurin-bin-17
  ];
  # hand edit gradle.lock from gradle_8_12_20241015: add org.gradle.kotlin.kotlin-dsl:org.gradle.kotlin.kotlin-dsl.gradle.plugin 5.1.2 org.jetbrains.kotlin:kotlin-build-tools-impl:2.0.21 dependencies, copy from gradle.lock from nearby gradle versions.
  bootstrapGradle = gradle_8_12_20241015;
}
