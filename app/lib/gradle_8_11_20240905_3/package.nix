# this is before gradle v8.11.0-M1. between gradle_8_11_20240905_2 and gradle_8_11_20240906_1
{
  temurin-bin-8,
  temurin-bin-11,
  temurin-bin-17,
  jdk21_headless,
  gradle_8_11_20240905_2,
  gradle-from-source,
  mergeLock,
}:
gradle-from-source {
  version = "8.11-20240905-3";
  rev = "ca18af3ba66160fc9247a5a78ac9fbed068cf90c";
  hash = "sha256-lMPVdGp5hHk/JygfbIJdALRBMyffQUn5eRzk3C4HfoI=";
  lockFile = mergeLock [
    gradle_8_11_20240905_2.unwrapped.passthru.lockFile
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
  bootstrapGradle = gradle_8_11_20240905_2;
}
