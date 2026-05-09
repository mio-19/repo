# this is before gradle_12_rc1. before commit https://github.com/gradle/gradle/commit/864ddaf0a289b122e804046ab4a0e618dce9b8e7
{
  jdk8_headless,
  jdk11_headless,
  jdk17_headless,
  jdk21_headless,
  gradle_8_11_M1,
  gradle-from-source,
}:
gradle-from-source {
  version = "8.11";
  hash = "sha256-E1+O/bVAw/YP9vJRFP5L3fje7gKnLdTXcCJlPq4ecaw=";
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
  # nix run github:tadfisher/gradle2nix/v2  -- --gradle-wrapper=8.11-milestone-1
  bootstrapGradle = gradle_8_11_M1;
}
