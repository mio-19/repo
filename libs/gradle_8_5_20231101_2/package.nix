# this is before gradle v8.5.0-RC1. before commit https://github.com/gradle/gradle/commit/094ef8b9eebb76ab9c2abc41e58026ace55b6e71
{
  temurin-bin-8,
  temurin-bin-11,
  temurin-bin-17,
  jdk21_headless,
  gradle_7_6,
  gradle-from-source,
}:
gradle-from-source {
  version = "8.5.0-20231101-2";
  rev = "eae2c238a854e8c925a70c18ebb169941578c0e6";
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
