# before https://github.com/gradle/gradle/commit/d377d9a97fa286e116cf2a0e294efef37d2a6f5e
{
  jdk8_headless,
  jdk11_headless,
  jdk17_headless,
  jdk21_headless,
  gradle_8_6_rc2,
  gradle-from-source,
}:
gradle-from-source {
  version = "8.7.0-20240118-1";
  rev = "28bfb012b44808ee4239d41a349869e49324a7ec";
  hash = "sha256-bxaB26lNuc+iiI6fxKtD6b2ZvowxYTIgiXy7i/ai38I=";
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
  # nix run github:tadfisher/gradle2nix/v2  -- --gradle-wrapper=8.6-rc-2
  bootstrapGradle = gradle_8_6_rc2;
}
