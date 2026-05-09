{
  jdk8_headless,
  jdk11_headless,
  jdk17_headless,
  jdk21_headless,
  gradle_8_9_rc1,
  gradle-from-source,
}:
gradle-from-source {
  version = "8.9.0-RC2";
  hash = "sha256-6DeytznOA/vEtQ460JjMW+r/7l8B9470QITs++Q0yDw=";
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
  # nix run github:tadfisher/gradle2nix/v2  -- --gradle-wrapper=8.9-rc-1
  bootstrapGradle = gradle_8_9_rc1;
}
