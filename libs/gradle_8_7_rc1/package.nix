{
  jdk8_headless,
  jdk11_headless,
  jdk17_headless,
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
  # gradle-from-source strips upstream Adoptium toolchain vendor requirements.
  buildJdk = jdk11_headless;
  javaToolchains = [
    jdk8_headless
    jdk11_headless
    jdk17_headless
  ];
  bootstrapGradle = gradle_8_7_20240126;
}
