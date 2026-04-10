# this is before gradle v8.11.0-M1. before commit https://github.com/gradle/gradle/commit/a2b280e1291afb5dc49d2b67837390dd5b85c6ed
{
  temurin-bin-8,
  temurin-bin-11,
  temurin-bin-17,
  jdk21_headless,
  gradle_8_11_1,
  gradle-from-source,
}:
gradle-from-source {
  version = "8.11-20240807";
  rev = "8a1e2cf697c428c5d15f39bb36109c970cd523bb";
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
