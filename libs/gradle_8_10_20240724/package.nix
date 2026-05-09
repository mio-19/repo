# before commit https://github.com/gradle/gradle/commit/5d3c2b0efa0e8c4eb0951ec483ea13e550e7e35b
{
  jdk8_headless,
  jdk11_headless,
  jdk17_headless,
  jdk21_headless,
  gradle_8_10_20240711,
  gradle-from-source,
  mergeLock,
}:
gradle-from-source {
  version = "8.10-20240724";
  rev = "6058693c57c73206c870bce9b04cdd0e85fa171b";
  hash = "sha256-DrAF0xanK61JkU8bntf1GdTKY8j0TC3XNwT8qh7DiXw=";
  lockFile = mergeLock [
    gradle_8_10_20240711.unwrapped.passthru.lockFile
    # [id: 'com.gradle.develocity', version: '3.17.6']
    ../gradle_8_10_rc1/gradle.lock
  ];
  defaultJava = jdk21_headless;
  # gradle-from-source strips upstream Adoptium toolchain vendor requirements.
  buildJdk = jdk11_headless;
  javaToolchains = [
    jdk8_headless
    jdk11_headless
    jdk17_headless
  ];
  bootstrapGradle = gradle_8_10_20240711;
}
