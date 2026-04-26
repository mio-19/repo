{
  temurin-bin-8,
  temurin-bin-11,
  temurin-bin-17,
  jdk21_headless,
  gradle_8_0_M1,
  gradle-from-source,
  mergeLock,
}:
gradle-from-source {
  version = "8.0.0-RC5";
  hash = "sha256-YUOGVXmwKsh+YubnTmzcnGi2brJA69gWcSzs5FNq9ik=";
  lockFile = mergeLock [
    gradle_8_0_M1.unwrapped.passthru.lockFile
    ./gradle.lock
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
  gradleFlags = [
    "-PbuildKotlinVersion=1.8.10"
    "--stacktrace"
  ];
  patches = [
    ./bootstrap-compat.patch
  ];
}
