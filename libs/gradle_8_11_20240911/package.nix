# this is before gradle v8.11.0-M1. before commit https://github.com/gradle/gradle/commit/f42b8312af060441d37ccde7b7ff9449d15aeaa9
{
  jdk8_headless,
  jdk11_headless,
  jdk17_headless,
  jdk21_headless,
  gradle_8_11_20240906,
  gradle-from-source,
  mergeLock,
}:
gradle-from-source {
  version = "8.11-20240911";
  rev = "b833359025724eaa4bef438b54d6277c9d5da4ff";
  hash = "sha256-WI4+JnQorP9HTJ/kCzgNzp6mfiWMzwrM/r3uZ5VA3qE=";
  lockFile = mergeLock [
    gradle_8_11_20240906.unwrapped.passthru.lockFile
    # org.gradle.buildtool.internal:configuration-cache-report:1.16
    ./more.gradle.lock
  ];
  defaultJava = jdk21_headless;
  # gradle-from-source strips upstream Adoptium toolchain vendor requirements.
  buildJdk = jdk11_headless;
  javaToolchains = [
    jdk8_headless
    jdk11_headless
    jdk17_headless
  ];
  bootstrapGradle = gradle_8_11_20240906;
}
