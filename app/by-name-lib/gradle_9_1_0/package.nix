{
  jdk17_headless,
  jdk21_headless,
  gradle-from-source,
  gradle_9_0_0_M1,
}:
gradle-from-source {
  version = "9.1.0";
  hash = "sha256-jh54xQwXeWSQjjYUbhyZHEIOXATKJUyYfmnqdkXmW+8=";
  lockFile = ./gradle.lock;
  defaultJava = jdk21_headless;
  buildJdk = jdk17_headless;
  bootstrapGradle = gradle_9_0_0_M1;
}
