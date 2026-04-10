# before https://github.com/gradle/gradle/commit/1ac201fb971f512686fd56ad2560f7ca5cf6771b
{
  temurin-bin-8,
  temurin-bin-11,
  temurin-bin-17,
  jdk21_headless,
  gradle_8_8,
  gradle-from-source,
}:
gradle-from-source {
  version = "8.9.0-20240411";
  rev = "5198078ea54d85e33bfd6a1859762353530e1997";
  hash = "sha256-CxdSGHZaJN8tZgNsjb6Uufpx+cEgZd8DZ4ZpnSdBePA=";
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
  # nix run github:tadfisher/gradle2nix/v2  -- --gradle-wrapper=8.8
  bootstrapGradle = gradle_8_8;
}
