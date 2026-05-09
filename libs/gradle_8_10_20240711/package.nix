# before commit https://github.com/gradle/gradle/commit/6204537b040168d666653d3a8cc27677f2c1beda
{
  jdk8_headless,
  jdk11_headless,
  jdk17_headless,
  jdk21_headless,
  gradle_8_9_rc2,
  gradle-from-source,
}:
gradle-from-source {
  version = "8.10-20240711";
  rev = "ca459184dd40fbf73a7e746d1e676bee3754c57d";
  hash = "sha256-yYDzYNw6ZjbvDrEaQhydB3PhL+iOc57NtqpgNMOI38w=";
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
  # nix run github:tadfisher/gradle2nix/v2  -- --gradle-wrapper=8.9-rc-2
  bootstrapGradle = gradle_8_9_rc2;
}
