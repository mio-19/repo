# before https://github.com/gradle/gradle/commit/a2060320d463db9da8a431b0f9c88ce2ebd4d886
{
  jdk8_headless,
  jdk11_headless,
  jdk17_headless,
  jdk21_headless,
  gradle_8_7_20240118_1,
  gradle-from-source,
  mergeLock,
}:
gradle-from-source {
  version = "8.7.0-20240118-3";
  rev = "7fce522c0d57e78741975babadb286989f7c1f72";
  hash = "sha256-+oxWCSomQVqUQeh+CmaJe3VjyhP+xRqN90rtA2ZtNhc=";
  lockFile = mergeLock [
    gradle_8_7_20240118_1.unwrapped.passthru.lockFile
    # org.gradle.kotlin.kotlin-dsl:org.gradle.kotlin.kotlin-dsl.gradle.plugin:4.3.0
    ../gradle_8_7_rc1/gradle.lock
  ];
  defaultJava = jdk21_headless;
  # gradle-from-source strips upstream Adoptium toolchain vendor requirements.
  buildJdk = jdk11_headless;
  javaToolchains = [
    jdk8_headless
    jdk11_headless
    jdk17_headless
  ];
  bootstrapGradle = gradle_8_7_20240118_1;
}
