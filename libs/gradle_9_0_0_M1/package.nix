{
  jdk17_headless,
  jdk21_headless,
  gradle-from-source,
  gradle_8_14_4,
}:
gradle-from-source {
  version = "9.0.0-M1";
  hash = "sha256-vgA8qodnXZoiizGwcn5IW+xMvCeGjxv2NwIqRBf2CPw=";
  lockFile = ./gradle.lock;
  defaultJava = jdk21_headless;
  buildJdk = jdk17_headless;
  # nix run github:tadfisher/gradle2nix/v2  -- --gradle-wrapper=8.14.4
  bootstrapGradle = gradle_8_14_4;
}
