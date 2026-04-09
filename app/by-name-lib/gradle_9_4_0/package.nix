{
  jdk17_headless,
  jdk25_headless,
  gradle-from-source,
  gradle_9_1_0,
}:
gradle-from-source {
  version = "9.4.0";
  hash = "sha256-U25RSle7sIWveYWXBeV4qg5TvVLTbciOJ71xOoAIBLg=";
  lockFile = ./gradle.lock;
  defaultJava = jdk25_headless;
  buildJdk = jdk17_headless;
  # nix run github:tadfisher/gradle2nix/v2 -- --gradle-wrapper=9.1.0
  bootstrapGradle = gradle_9_1_0;
}
