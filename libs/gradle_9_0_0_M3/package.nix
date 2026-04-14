{
  jdk17_headless,
  jdk21_headless,
  gradle-from-source,
  gradle_9_0_0_M1,
}:
gradle-from-source {
  version = "9.0.0-M3";
  hash = "sha256-yQOqZqaU+Jja56xbqGYG+nExxxmrj0b4IZ3FnGEM6II=";
  lockFile = ./gradle.lock;
  defaultJava = jdk21_headless;
  buildJdk = jdk17_headless;
  # nix run github:tadfisher/gradle2nix/v2 -- --gradle-dist=https://services.gradle.org/distributions/gradle-9.0-milestone-1-bin.zip
  bootstrapGradle = gradle_9_0_0_M1;
  configureOnDemand = true;
}
