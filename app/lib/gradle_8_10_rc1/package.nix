{
  temurin-bin-8,
  temurin-bin-11,
  temurin-bin-17,
  jdk21_headless,
  gradle_8_10_20240724,
  gradle-from-source,
  runCommand,
  jq,
  lib,
}:
gradle-from-source {
  version = "8.10.0-RC1";
  hash = "";
  # nix-shell -p javaPackages.compiler.openjdk11-bootstrap
  # nix run github:tadfisher/gradle2nix/v2  -- --gradle-wrapper=8.10-rc-1
  # why generate lock file with 8.10-rc-1? beacuse it is easier. it doesn't match bootstrapGradle.
  lockFile = ./gradle.lock;
  defaultJava = jdk21_headless;
  # this version specifically ask for termurin branded jdk.
  buildJdk = temurin-bin-11;
  javaToolchains = [
    temurin-bin-8
    temurin-bin-11
    temurin-bin-17
  ];
  bootstrapGradle = gradle_8_10_20240724;
}
