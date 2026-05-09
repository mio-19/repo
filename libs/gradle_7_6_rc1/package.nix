{
  temurin-bin-8,
  temurin-bin-11,
  temurin-bin-17,
  jdk17_headless,
  gradle-from-source,
  gradle_7_6_M1,
  mergeLock,
}:
gradle-from-source {
  version = "7.6.0-RC1";
  hash = "sha256-CWHRq84wSXUiPkKOHnRLyFdAH7GME1kw4cA5WbQgolE=";
  lockFile = mergeLock [
    gradle_7_6_M1.unwrapped.passthru.lockFile
    ./more.gradle.lock
  ];
  defaultJava = jdk17_headless;
  # this version specifically ask for termurin branded jdk.
  buildJdk = temurin-bin-11;
  javaToolchains = [
    temurin-bin-8
    temurin-bin-11
    temurin-bin-17
  ];
  bootstrapGradle = gradle_7_6_M1;
}
