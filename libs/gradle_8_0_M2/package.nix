{
  temurin-bin-8,
  temurin-bin-11,
  temurin-bin-17,
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
  # this version specifically ask for termurin branded jdk.
  buildJdk = temurin-bin-11;
  javaToolchains = [
    temurin-bin-8
    temurin-bin-11
    temurin-bin-17
  ];
  bootstrapGradle = gradle_8_0_M1;
}
