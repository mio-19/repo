# this is before gradle v8.11.0-M1. before commit https://github.com/gradle/gradle/commit/2f69db976de6317e79a8fdcb26be42928a8f90ab
{
  temurin-bin-8,
  temurin-bin-11,
  temurin-bin-17,
  jdk21_headless,
  gradle_8_11_20240904,
  gradle-from-source,
  mergeLock,
}:
gradle-from-source {
  version = "8.11-20240905-1";
  rev = "b94bbd90f6c3da3f5f10a60dd2b1f1d75b51dd83";
  hash = "";
  lockFile = mergeLock [
    gradle_8_11_20240904.unwrapped.passthru.lockFile
    ./more.gradle.lock
  ];
  defaultJava = jdk21_headless;
  # this version specifically ask for termurin branded jdk.
  buildJdk = temurin-bin-11;
  javaToolchains = [
    temurin-bin-8
    temurin-bin-11
    temurin-bin-17
  ];
  bootstrapGradle = gradle_8_11_20240904;
}
