{
  jdk17_headless,
  jdk25_headless,
  gradle-from-source,
  gradle_8_14_4,
}:
gradle-from-source {
  version = "9.4.0";
  hash = "";
  lockFile = ./gradle.lock;
  defaultJava = jdk25_headless;
  buildJdk = jdk17_headless;
  bootstrapGradle = gradle_8_14_4;
}
