# this is before gradle_12_rc1. https://github.com/gradle/gradle/commit/864ddaf0a289b122e804046ab4a0e618dce9b8e7
{
  temurin-bin-8,
  temurin-bin-11,
  temurin-bin-17,
  jdk21_headless,
  gradle_8_12_20241015,
  gradle-from-source,
}:
gradle-from-source {
  version = "8.12-20241016-864d";
  rev = "864ddaf0a289b122e804046ab4a0e618dce9b8e7";
  hash = "";
  lockFile = ./gradle.lock;
  defaultJava = jdk21_headless;
  # this version specifically ask for termurin branded jdk.
  buildJdk = temurin-bin-17;
  javaToolchains = [
    temurin-bin-8
    temurin-bin-11
    temurin-bin-17
  ];
  # nix-shell -p javaPackages.compiler.openjdk17-bootstrap
  # nix run github:tadfisher/gradle2nix/effc6f3c8ba22e718eb4fb31f09219d0fcc75649  -- --gradle-wrapper=8.12-rc-1
  bootstrapGradle = gradle_8_12_20241015;
}
