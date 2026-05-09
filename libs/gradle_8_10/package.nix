{
  jdk8_headless,
  jdk11_headless,
  jdk17_headless,
  jdk21_headless,
  gradle_8_10_rc1,
  gradle-from-source,
}:
gradle-from-source {
  version = "8.10";
  hash = "sha256-gH95GsRuLgRZKsNa2ZagfQb5tDEgbWHZWooulCFB2mo=";
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
  # nix run github:tadfisher/gradle2nix/v2  -- --gradle-wrapper=8.10-rc-1
  bootstrapGradle = gradle_8_10_rc1;
  configureOnDemand = true;
}
