# this is before gradle v8.11.0-M1. before commit https://github.com/gradle/gradle/commit/ea3f2b4ff4b17341830905cad9c7fa1b2db7f03b
{
  jdk8_headless,
  jdk11_headless,
  jdk17_headless,
  jdk21_headless,
  gradle_8_11_20240809,
  gradle-from-source,
  mergeLock,
}:
gradle-from-source {
  version = "8.11-20240903";
  rev = "72bdc3250c2efab2d5113f47f49d4139ccd18ee5";
  hash = "sha256-G2kipnZ2F13xKPnpB8MtNA9qWFV818KUMgvgN3AUQG8=";
  lockFile = mergeLock [
    gradle_8_11_20240809.unwrapped.passthru.lockFile
  ];
  defaultJava = jdk21_headless;
  # gradle-from-source strips upstream Adoptium toolchain vendor requirements.
  buildJdk = jdk11_headless;
  javaToolchains = [
    jdk8_headless
    jdk11_headless
    jdk17_headless
  ];
  bootstrapGradle = gradle_8_11_20240809;
}
