# this is before gradle v8.5.0-RC1. before commit https://github.com/gradle/gradle/commit/ef6ed7d0aa4915ae8804c98b30c8798acdc8c447
{
  temurin-bin-8,
  temurin-bin-11,
  temurin-bin-17,
  jdk21_headless,
  gradle_7_6,
  gradle-from-source,
}:
gradle-from-source {
  version = "8.5.0-20231031-1";
  rev = "48ed450140e5b70b61ff05f0a0f82300251ca31f";
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
