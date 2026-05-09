# before https://github.com/gradle/gradle/commit/7f8365f4a6492eb0e8acbbb37be1f30352ebbaa6
{
  jdk8_headless,
  jdk11_headless,
  jdk17_headless,
  jdk21_headless,
  gradle-from-source,
  mergeLock,
  gradle_8_9_20240411,
}:
gradle-from-source {
  version = "8.9.0-20240529";
  rev = "8a9cda36b91f1b7f66d0c2c27e5594a210bac8f3";
  hash = "sha256-IplC2CQp/ZWMn37fUByaHF9/X04Ey4Q4vfmFaPXCqQA=";
  # [id: 'com.gradle.develocity', version: '3.17.4']
  lockFile = mergeLock [
    gradle_8_9_20240411.unwrapped.passthru.lockFile
    ./more.gradle.lock
    # [id: 'org.gradle.kotlin.kotlin-dsl', version: '4.4.0']
    ../gradle_8_9_rc1/gradle.lock
  ];
  defaultJava = jdk21_headless;
  # gradle-from-source strips upstream Adoptium toolchain vendor requirements.
  buildJdk = jdk11_headless;
  javaToolchains = [
    jdk8_headless
    jdk11_headless
    jdk17_headless
  ];
  bootstrapGradle = gradle_8_9_20240411;
}
