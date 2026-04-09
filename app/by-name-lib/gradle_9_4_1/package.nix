{
  jdk17_headless,
  jdk21_headless,
  gradle-from-source,
  gradle_8_14_4,
}:
gradle-from-source {
  version = "9.4.1";
  hash = "sha256-eIdVEbRO1Q8RfZTN1oqw4iWPMImTR81UkT+xHZbn1xs=";
  lockFile = ./gradle.lock;
  defaultJava = jdk21_headless;
  buildJdk = jdk17_headless;
  bootstrapGradle = gradle_8_14_4;
}
