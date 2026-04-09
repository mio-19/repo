{
  jdk17_headless,
  jdk21_headless,
  gradle-from-source,
  gradle_9_1_0,
}:
gradle-from-source {
  version = "9.3.1";
  hash = "sha256-uDc2w+D/xxK/2rguf48eUZ9UPYtVpMePfnJOKh/NNCE=";
  lockFile = ./gradle.lock;
  defaultJava = jdk21_headless;
  buildJdk = jdk17_headless;
  # nix run github:tadfisher/gradle2nix/v2 -- --gradle-wrapper=9.1.0
  bootstrapGradle = gradle_9_1_0;
}
