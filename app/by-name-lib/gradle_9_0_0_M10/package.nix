{
  jdk17_headless,
  jdk21_headless,
  gradle-from-source,
  gradle_9_0_0_M8,
}:
gradle-from-source {
  version = "9.0.0-M10";
  hash = "";
  lockFile = ./gradle.lock;
  defaultJava = jdk21_headless;
  buildJdk = jdk17_headless;
  # nix run github:tadfisher/gradle2nix/v2 -- --gradle-dist=https://services.gradle.org/distributions/gradle-9.0.0-milestone-8-bin.zip
  bootstrapGradle = gradle_9_0_0_M8;
}
