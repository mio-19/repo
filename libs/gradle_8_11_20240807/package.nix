# this is before gradle v8.11.0-M1. before commit https://github.com/gradle/gradle/commit/a2b280e1291afb5dc49d2b67837390dd5b85c6ed
{
  jdk8_headless,
  jdk11_headless,
  jdk17_headless,
  jdk21_headless,
  gradle_8_10,
  gradle-from-source,
}:
gradle-from-source {
  version = "8.11-20240807";
  rev = "8a1e2cf697c428c5d15f39bb36109c970cd523bb";
  hash = "sha256-08AJLr/ffus4gczX0DQnSIUfGJEGxwpII8PJOlwM9J8=";
  lockFile = ./gradle.lock;
  defaultJava = jdk21_headless;
  # gradle-from-source strips upstream Adoptium toolchain vendor requirements.
  buildJdk = jdk11_headless;
  javaToolchains = [
    jdk8_headless
    jdk11_headless
    jdk17_headless
  ];
  # nix-shell -p javaPackages.compiler.openjdk11-bootstrap
  # nix run github:tadfisher/gradle2nix/v2  -- --gradle-wrapper=8.10
  bootstrapGradle = gradle_8_10;
}
