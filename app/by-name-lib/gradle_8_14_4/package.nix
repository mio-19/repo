{
  jdk11_headless,
  jdk21_headless,
  gradle_8_14,
  gradle-from-source,
}:
gradle-from-source {
  version = "8.14.4";
  hash = "sha256-DzIJ4bPmyOj58GEpdAS9MZ4APmT5NKgNhiNp/UwZbhY=";
  lockFile = ./gradle.lock;
  defaultJava = jdk21_headless;
  buildJdk = jdk11_headless;
  # nix run github:tadfisher/gradle2nix/53672d5e875235c34dee1a4c012b0269ba76e440  -- --gradle-wrapper=8.14
  bootstrapGradle = gradle_8_14;
}
