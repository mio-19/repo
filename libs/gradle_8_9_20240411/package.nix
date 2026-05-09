# before https://github.com/gradle/gradle/commit/1ac201fb971f512686fd56ad2560f7ca5cf6771b
{
  jdk8_headless,
  jdk11_headless,
  jdk17_headless,
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
  # gradle-from-source strips upstream Adoptium toolchain vendor requirements.
  buildJdk = jdk11_headless;
  javaToolchains = [
    jdk8_headless
    jdk11_headless
    jdk17_headless
  ];
  # nix-shell -p javaPackages.compiler.openjdk11-bootstrap
  # nix run github:tadfisher/gradle2nix/v2  -- --gradle-wrapper=8.8
  bootstrapGradle = gradle_8_8;
  configureOnDemand = true;
}
