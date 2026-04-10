# this is before gradle v8.11.0-M1. before commit https://github.com/gradle/gradle/commit/f42b8312af060441d37ccde7b7ff9449d15aeaa9
{
  temurin-bin-8,
  temurin-bin-11,
  temurin-bin-17,
  jdk21_headless,
  gradle_8_11_1,
  gradle-from-source,
}:
gradle-from-source {
  version = "8.11-20240911";
  rev = "b833359025724eaa4bef438b54d6277c9d5da4ff";
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
