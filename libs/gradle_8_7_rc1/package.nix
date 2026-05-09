{
  temurin-bin-8,
  temurin-bin-11,
  temurin-bin-17,
  jdk21_headless,
  gradle_8_7_20240126,
  gradle-from-source,
}:
gradle-from-source {
  version = "8.7.0-RC1";
  hash = "sha256-WHFq5QGtiL8GNkilJ2sUzd65lRl1DigWrPooQLnx3ZU=";
  # nix-shell -p javaPackages.compiler.openjdk11-bootstrap
  # nix run github:tadfisher/gradle2nix/v2  -- --gradle-wrapper=8.7-rc-1
  # why generate lock file with different version? beacuse it is easier. it doesn't match bootstrapGradle.
  lockFile = ./gradle.lock;
  defaultJava = jdk21_headless;
  # this version specifically ask for termurin branded jdk.
  buildJdk = temurin-bin-11;
  javaToolchains = [
    temurin-bin-8
    temurin-bin-11
    temurin-bin-17
  ];
  bootstrapGradle = gradle_8_7_20240126;
}
