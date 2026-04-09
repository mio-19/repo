{
  jdk17_headless,
  jdk21_headless,
  gradle-from-source,
  gradle_8_14_4,
}:
gradle-from-source {
  version = "9.1.0";
  hash = "";
  lockFile = ./gradle.lock;
  defaultJava = jdk21_headless;
  buildJdk = jdk17_headless;
  bootstrapGradle = gradle_8_14_4;
}
