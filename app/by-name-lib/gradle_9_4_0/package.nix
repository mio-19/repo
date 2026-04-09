{
  jdk17_headless,
  jdk25_headless,
  gradle-from-source,
  gradle_8_14_4,
}:
gradle-from-source {
  version = "9.4.0";
  hash = "sha256-U25RSle7sIWveYWXBeV4qg5TvVLTbciOJ71xOoAIBLg=";
  lockFile = ./gradle.lock;
  defaultJava = jdk25_headless;
  buildJdk = jdk17_headless;
  bootstrapGradle = gradle_8_14_4;
}
