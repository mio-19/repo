{
  temurin-bin-8,
  temurin-bin-11,
  temurin-bin-17,
  jdk17_headless,
  gradle-from-source,
  gradle_7_6_rc4,
  mergeLock,
}:
gradle-from-source {
  version = "7.6.0";
  hash = "sha256-RWEALk7H51a3ztnA6UFJVLjQIthfpruP1e22TD/LnR8=";
  lockFile = mergeLock [
    gradle_7_6_rc4.unwrapped.passthru.lockFile
  ];
  defaultJava = jdk17_headless;
  # this version specifically ask for termurin branded jdk.
  buildJdk = temurin-bin-11;
  javaToolchains = [
    temurin-bin-8
    temurin-bin-11
    temurin-bin-17
  ];
  bootstrapGradle = gradle_7_6_rc4;
}
