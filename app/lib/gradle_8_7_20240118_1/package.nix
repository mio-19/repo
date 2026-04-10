# before https://github.com/gradle/gradle/commit/d377d9a97fa286e116cf2a0e294efef37d2a6f5e
{
  temurin-bin-8,
  temurin-bin-11,
  temurin-bin-17,
  jdk21_headless,
  gradle_8_6_rc2,
  gradle-from-source,
}:
gradle-from-source {
  version = "8.7.0-20240118-1";
  rev = "28bfb012b44808ee4239d41a349869e49324a7ec";
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
  # nix run github:tadfisher/gradle2nix/v2  -- --gradle-wrapper=8.6-rc-2
  bootstrapGradle = gradle_8_6_rc2;
}
