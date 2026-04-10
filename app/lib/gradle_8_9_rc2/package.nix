{
  temurin-bin-8,
  temurin-bin-11,
  temurin-bin-17,
  jdk21_headless,
  gradle_8_9_rc1,
  gradle-from-source,
}:
gradle-from-source {
  version = "8.9.0-RC2";
  hash = "sha256-6DeytznOA/vEtQ460JjMW+r/7l8B9470QITs++Q0yDw=";
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
  # nix run github:tadfisher/gradle2nix/v2  -- --gradle-wrapper=8.9-rc-1
  bootstrapGradle = gradle_8_9_rc1;
}
