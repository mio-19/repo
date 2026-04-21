{
  temurin-bin-8,
  temurin-bin-11,
  temurin-bin-17,
  jdk21_headless,
  gradle_8_2,
  gradle-from-source,
  mergeLock,
}:
gradle-from-source {
  version = "8.3.0-20230705";
  rev = "5c999293af0b1d5f254582c661de699ec84ec608";
  hash = "sha256-a1Pw5qtb8ycUBrqAlAxm89TMJWGQ4lODOIKV1CGWrJs=";
  lockFile = mergeLock [
    gradle_8_2.unwrapped.passthru.lockFile
    ./gradle.lock
  ];
  defaultJava = jdk21_headless;
  buildJdk = temurin-bin-11;
  javaToolchains = [
    temurin-bin-8
    temurin-bin-11
    temurin-bin-17
  ];
  bootstrapGradle = gradle_8_2;
  gradleFlags = [
    "-PbuildKotlinVersion=1.8.21"
  ];
}
