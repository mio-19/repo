{
  jdk17_headless,
  jdk21_headless,
  gradle_8_13,
  gradle-from-source,
}:
gradle-from-source {
  version = "8.14.0-M8";
  hash = "sha256-uP5XNVZO/gW3NQpIv3EMXlIWI8OCY8qSJWIgTysLl0k=";
  lockFile = ./gradle.lock;
  defaultJava = jdk21_headless;
  buildJdk = jdk17_headless;
  # nix-shell -p jdk17
  # nix run github:tadfisher/gradle2nix/53672d5e875235c34dee1a4c012b0269ba76e440  -- --gradle-wrapper=8.13
  bootstrapGradle = gradle_8_13;
}
