{
  jdk8_headless,
  jdk11_headless,
  jdk17_headless,
  jdk21_headless,
  gradle_8_2_bootstrap,
  gradle-from-source,
  mergeLock,
}:
gradle-from-source {
  version = "8.3.0-20230705";
  rev = "5c999293af0b1d5f254582c661de699ec84ec608";
  hash = "sha256-a1Pw5qtb8ycUBrqAlAxm89TMJWGQ4lODOIKV1CGWrJs=";
  lockFile = mergeLock [
    gradle_8_2_bootstrap.unwrapped.passthru.lockFile
    ./gradle.lock
  ];
  defaultJava = jdk21_headless;
  buildJdk = jdk11_headless;
  javaToolchains = [
    jdk8_headless
    jdk11_headless
    jdk17_headless
  ];
  bootstrapGradle = gradle_8_2_bootstrap;
  gradleFlags = [
    "-PbuildKotlinVersion=1.8.21"
  ];
}
