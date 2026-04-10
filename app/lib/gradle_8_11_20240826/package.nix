# this is before gradle v8.11.0-M1. before commit https://github.com/gradle/gradle/commit/22b62d3e0f96288dcbd0e12bea9669848338233c
{
  temurin-bin-8,
  temurin-bin-11,
  temurin-bin-17,
  jdk21_headless,
  gradle_8_11_1,
  gradle-from-source,
}:
gradle-from-source {
  version = "8.11-20240826";
  rev = "4ef924c4d260b5f629e4d1641c61d60fc42e9725";
  hash = "";
  lockFile = ./gradle.lock;
  defaultJava = jdk21_headless;
  # this version specifically ask for termurin branded jdk.
  buildJdk = temurin-bin-11;
  javaToolchains = [
    temurin-bin-8
    temurin-bin-11
    temurin-bin-17
  ];
  # nix-shell -p javaPackages.compiler.openjdk11-bootstrap
  # nix run github:tadfisher/gradle2nix/v2  -- --gradle-wrapper=8.10.2
  bootstrapGradle = gradle_8_11_1;
}
