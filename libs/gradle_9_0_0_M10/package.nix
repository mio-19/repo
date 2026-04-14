{
  jdk17_headless,
  jdk21_headless,
  gradle-from-source,
  gradle_9_0_0_M7,
}:
gradle-from-source {
  version = "9.0.0-M10";
  hash = "sha256-0gGxa6WeKAWWj2eXL0/9zYahIG03Sl7TvQyX8wq5+KI=";
  lockFile = ./gradle.lock;
  defaultJava = jdk21_headless;
  buildJdk = jdk17_headless;
  # nix run github:tadfisher/gradle2nix/v2 -- --gradle-dist=https://services.gradle.org/distributions/gradle-9.0-milestone-7-bin.zip
  bootstrapGradle = gradle_9_0_0_M7;
  configureOnDemand = true;
}
