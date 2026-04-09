{
  jdk17_headless,
  jdk21_headless,
  gradle-from-source,
  gradle_9_0_0_M4,
}:
gradle-from-source {
  version = "9.0.0-M9";
  hash = "";
  lockFile = ./gradle.lock;
  defaultJava = jdk21_headless;
  buildJdk = jdk17_headless;
  # nix run github:tadfisher/gradle2nix/v2 -- --gradle-dist=https://services.gradle.org/distributions/gradle-9.0-milestone-4-bin.zip
  bootstrapGradle = gradle_9_0_0_M4;
}
