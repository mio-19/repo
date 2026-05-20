{
  jdk8_headless,
  jdk11_headless,
  jdk17_headless,
  jdk21_headless,
  gradle_8_0_M1,
  gradle_8_0_20220911,
  gradle-from-source,
  mergeLock,
  lib,
}:
gradle-from-source {
  version = "8.0.0-M2";
  tag = "v8.0.0-M2";
  hash = "sha256-j5rcQtPu5ioyepXjXF20hFp0SvSuruTArC2QFhRL/44=";
  lockFile = mergeLock [
    gradle_8_0_M1.unwrapped.passthru.lockFile
    gradle_8_0_20220911.unwrapped.passthru.lockFile
    ../gradle_8_0/more.gradle.lock
  ];
  defaultJava = jdk21_headless;
  # this version specifically ask for Temurin branded jdk.
  relaxJavaVendor = true;
  buildJdk = jdk11_headless;
  javaToolchains = [
    jdk8_headless
    jdk11_headless
    jdk17_headless
  ];
  bootstrapGradle = gradle_8_0_M1;
}
